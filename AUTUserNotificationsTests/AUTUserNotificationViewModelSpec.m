//
//  AUTUserNotificationsViewModelSpec.m
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Specta;
@import Expecta;
#import <AUTUserNotifications/AUTUserNotifications.h>

#import "AUTStubUserNotifier.h"
#import "AUTStubUserNotificationHandler.h"
#import "AUTStubRemoteNotificationRegistrar.h"
#import "AUTStubRemoteNotificationFetchHandler.h"
#import "AUTStubUserNotificationActionHandler.h"
#import "AUTTestLocalUserNotification.h"
#import "AUTTestLocalUserNotificationSubclass.h"
#import "AUTTestRootRemoteUserNotification.h"
#import "AUTTestChildRemoteUserNotification.h"

SpecBegin(AUTUserNotificationsViewModel)

__block NSError *error;
__block BOOL success;

__block AUTStubUserNotificationHandler *stubNotificationHandler;
__block AUTStubUserNotifier *stubNotifier;
__block AUTStubRemoteNotificationRegistrar *stubRegistrar;
__block AUTUserNotificationsViewModel *viewModel;

beforeEach(^{
    error = nil;
    success = NO;

    stubNotificationHandler = [[AUTStubUserNotificationHandler alloc] init];
    stubNotifier = [[AUTStubUserNotifier alloc] initWithHandler:stubNotificationHandler];
    stubRegistrar = [[AUTStubRemoteNotificationRegistrar alloc] init];

    viewModel = [[AUTUserNotificationsViewModel alloc]
        initWithNotifier:stubNotifier
        handler:stubNotificationHandler
        rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class];
});

describe(@"lifecycle", ^{
    it(@"should deallocate", ^{
        RACSignal *willDealloc;
        @autoreleasepool {
            AUTUserNotificationsViewModel *viewModel = [[AUTUserNotificationsViewModel alloc]
                initWithNotifier:stubNotifier
                handler:stubNotificationHandler
                rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class];

            willDealloc = viewModel.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();
    });
});

describe(@"-registerSettingsCommand", ^{
    it(@"should register settings", ^{
        UIUserNotificationSettings *settings = [[UIUserNotificationSettings alloc] init];

        UIUserNotificationSettings *registeredSettings = [[viewModel.registerSettingsCommand execute:settings] asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(registeredSettings).to.beIdenticalTo(settings);
        expect(error).to.beNil();
        expect(success).to.beTruthy();

        expect(stubNotifier.currentUserNotificationSettings).to.beIdenticalTo(settings);
    });
});

describe(@"-registerForRemoteNotificationsCommand", ^{
    it(@"should perform registration with the registrar", ^{
        NSData *token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];

        // Provide the token to the stubbed notifier
        stubNotifier.remoteNotificationRegistrationDeviceToken = token;
        viewModel.tokenRegistrar = stubRegistrar;

        success = [[viewModel.registerForRemoteNotificationsCommand execute:nil] asynchronouslyWaitUntilCompleted:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();

        expect(stubRegistrar.registeredDeviceToken).to.beIdenticalTo(token);
    });

    it(@"should be disabled when no token registrar is set", ^{
        NSNumber *enabled = [viewModel.registerForRemoteNotificationsCommand.enabled asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();

        expect(enabled).notTo.beNil();
        expect(enabled).to.beFalsy();
    });
});

describe(@"-receivedNotificationsOfClass:", ^{
    describe(@"local notifications", ^{
        it(@"should receive filtered local notifications", ^{
            AUTTestLocalUserNotification *notificationSubclass = [[AUTTestLocalUserNotification alloc] init];
            AUTLocalUserNotification *notificationSuperclass = [[AUTLocalUserNotification alloc] init];

            RACSubject *finishReceiving = [RACSubject subject];

            RACSignal *receivedSubclasses = [[[viewModel receivedNotificationsOfClass:notificationSubclass.class]
                takeUntil:finishReceiving]
                replay];

            expect([[viewModel scheduleLocalNotification:notificationSuperclass] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
            expect(error).to.beNil();

            expect([[viewModel scheduleLocalNotification:notificationSubclass] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
            expect(error).to.beNil();

            [finishReceiving sendCompleted];

            NSArray *receivedNotifications = [[receivedSubclasses collect] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotifications).to.beKindOf(NSArray.class);
            expect(receivedNotifications).to.haveACountOf(1);
            expect(receivedNotifications.firstObject).to.beAnInstanceOf(notificationSubclass.class);
            expect(receivedNotifications.firstObject).to.equal(notificationSubclass);
            expect(receivedNotifications.firstObject).notTo.beIdenticalTo(notificationSubclass);
        });

        it(@"should receive notifications from an application launch", ^{
            AUTLocalUserNotification *notification = [[AUTLocalUserNotification alloc] init];

            RACSignal *receivedNotifications = [[viewModel receivedNotificationsOfClass:AUTLocalUserNotification.class]
                replay];

            UILocalNotification *systemNotification = [notification createSystemNotification];
            expect(systemNotification).to.beKindOf(UILocalNotification.class);

            [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil userInfo:@{
                UIApplicationLaunchOptionsLocalNotificationKey: systemNotification,
            }];

            AUTLocalUserNotification *receivedNotification = [receivedNotifications asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.beAnInstanceOf(AUTLocalUserNotification.class);
            expect(receivedNotification).to.equal(notification);
            expect(receivedNotification).notTo.beIdenticalTo(notification);
        });
    });

    describe(@"remote notifications", ^{
        it(@"should receive filtered remote notifications", ^{
            Class notificationSubclass = AUTTestChildRemoteUserNotification.class;
            Class notificationSuperclass = AUTTestRootRemoteUserNotification.class;

            RACSubject *finishReceiving = [RACSubject subject];

            RACSignal *receivedSubclasses = [[[viewModel receivedNotificationsOfClass:AUTTestChildRemoteUserNotification.class]
                takeUntil:finishReceiving]
                replay];

            [stubNotifier displayRemoteNotification:[notificationSubclass asJSONDictionary]];
            [stubNotifier displayRemoteNotification:[notificationSuperclass asJSONDictionary]];

            [finishReceiving sendCompleted];

            NSArray *receivedNotifications = [[receivedSubclasses collect] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotifications).to.beKindOf(NSArray.class);
            expect(receivedNotifications).to.haveACountOf(1);
            expect(receivedNotifications.firstObject).to.beAnInstanceOf(notificationSubclass.class);
        });

        it(@"should receive notifications from an application launch", ^{
            RACSignal *receivedNotifications = [[viewModel receivedNotificationsOfClass:AUTTestRootRemoteUserNotification.class]
                replay];

            [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil userInfo:@{
                UIApplicationLaunchOptionsRemoteNotificationKey: [AUTTestRootRemoteUserNotification asJSONDictionary],
            }];

            AUTTestRootRemoteUserNotification *receivedNotification = [receivedNotifications asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.beAnInstanceOf(AUTTestRootRemoteUserNotification.class);
        });
    });
});

describe(@"-registerFetchHandler:forRemoteUserNotificationsOfClass:", ^{
    __block void (^completionHandler)(UIBackgroundFetchResult) = nil;
    __block RACSubject *fetchResult;
    __block AUTStubRemoteNotificationFetchHandler *stubFetchHandler;

    beforeEach(^{
        fetchResult = [RACSubject subject];
        completionHandler = ^(UIBackgroundFetchResult result) {
            [fetchResult sendNext:@(result)];
            [fetchResult sendCompleted];
        };
        stubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
    });

    it(@"should indicate that no data was fetched when no fetch handlers are registered", ^{
        RACSignal *replayedFetchResult = [fetchResult replay];

        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

        NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(UIBackgroundFetchResultNoData));
    });

    it(@"should execute the completion handler with the result of the fetch handler", ^{
        UIBackgroundFetchResult fetchHandlerResult = UIBackgroundFetchResultNewData;
        stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

        [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

        RACSignal *replayedFetchResult = [fetchResult replay];

        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

        NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(fetchHandlerResult));

        expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
    });

    it(@"should not retain handlers", ^{
        RACSignal *willDealloc;
        @autoreleasepool {
            AUTStubRemoteNotificationFetchHandler *stubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            willDealloc = stubFetchHandler.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should gracefully fail when receiving notifications with handlers that have been deallocated", ^{
        RACSignal *willDealloc;
        @autoreleasepool {
            AUTStubRemoteNotificationFetchHandler *stubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            willDealloc = stubFetchHandler.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();

        RACSignal *replayedFetchResult = [fetchResult replay];

        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

        NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(UIBackgroundFetchResultNoData));
    });

    it(@"should remove the handler upon disposal", ^{
        __block NSInteger invocations = 0;
        stubFetchHandler.fetchHandler = [[RACSignal return:@(UIBackgroundFetchResultNoData)] doNext:^(id _) {
            invocations++;
        }];

        RACDisposable *disposable = [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
        [disposable dispose];

        RACSignal *replayedFetchResult = [fetchResult replay];

        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

        NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();

        expect(invocations).to.equal(0);
    });

    describe(@"multiple handlers", ^{
        __block AUTStubRemoteNotificationFetchHandler *anotherStubFetchHandler;

        beforeEach(^{
            anotherStubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
        });

        it(@"should execute the completion handler with the worst handler result", ^{
            UIBackgroundFetchResult fetchHandlerResult = UIBackgroundFetchResultNoData;
            stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

            // Failure is worse than "no data".
            UIBackgroundFetchResult anotherFetchHandlerResult = UIBackgroundFetchResultFailed;
            anotherStubFetchHandler.fetchHandler = [RACSignal return:@(anotherFetchHandlerResult)];

            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            [viewModel registerFetchHandler:anotherStubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

            RACSignal *replayedFetchResult = [fetchResult replay];

            NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
            [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

            NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(systemResult).notTo.beNil();
            expect(systemResult).to.equal(@(anotherFetchHandlerResult));

            expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
            expect(anotherStubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
        });

        it(@"should subscribe to the returned fetch handler signal for each registered handler", ^{
            __block NSInteger invocations = 0;
            RACSignal *fetchHandler = [[RACSignal return:@(UIBackgroundFetchResultNoData)] doNext:^(id _) {
                invocations++;
            }];

            stubFetchHandler.fetchHandler = fetchHandler;
            anotherStubFetchHandler.fetchHandler = fetchHandler;

            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            [viewModel registerFetchHandler:anotherStubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

            RACSignal *replayedFetchResult = [fetchResult replay];

            NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
            [stubNotifier sendSilentRemoteNotification:notification fetchCompletionHandler:completionHandler];

            NSNumber *systemResult = [replayedFetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(systemResult).notTo.beNil();

            expect(invocations).to.equal(2);

            expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
            expect(anotherStubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
        });
    });
});

describe(@"registerActionHandler:forNotificationsOfClass:", ^{
    __block void (^completionHandler)() = nil;
    __block RACSubject *actionCompleted;
    __block AUTStubUserNotificationActionHandler *stubActionHandler;

    NSString * const actionIdentifier = @"an action";

    beforeEach(^{
        actionCompleted = [RACSubject subject];
        completionHandler = ^() {
            [actionCompleted sendCompleted];
        };
        stubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
    });

    it(@"should invoke the action completion handler when no action handlers are registered", ^{
        RACSignal *replayedActionCompleted = [actionCompleted replay];

        NSString *actionIdentifier = @"an action";
        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier performActionWithIdentifier:actionIdentifier forRemoteNotification:notification completionHandler:completionHandler];

        expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should invoke the action completion handler after invoking the registered action handler for a remote notification", ^{
        RACSubject *actionHandlerInvoked = [RACReplaySubject replaySubjectWithCapacity:0];
        stubActionHandler.actionHandler = [[RACSignal empty] doCompleted:^{
            [actionHandlerInvoked sendCompleted];
        }];

        Class notificationClass = AUTTestChildRemoteUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];

        RACSignal *replayedActionCompleted = [actionCompleted replay];

        NSDictionary *notification = [notificationClass asJSONDictionary];
        [stubNotifier performActionWithIdentifier:actionIdentifier forRemoteNotification:notification completionHandler:completionHandler];

        expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass);
        expect(stubActionHandler.notification.actionIdentifier).to.equal(actionIdentifier);
    });

    it(@"should invoke the action completion handler after invoking the registered action handler for a local notification", ^{
        RACSubject *actionHandlerInvoked = [RACReplaySubject replaySubjectWithCapacity:0];
        stubActionHandler.actionHandler = [[RACSignal empty] doCompleted:^{
            [actionHandlerInvoked sendCompleted];
        }];

        Class notificationClass = AUTTestLocalUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];

        RACSignal *replayedActionCompleted = [actionCompleted replay];

        AUTTestLocalUserNotification *notification = [[notificationClass alloc] init];
        UILocalNotification *systemNotification = [notification createSystemNotification];
        [stubNotifier performActionWithIdentifier:actionIdentifier forLocalNotification:systemNotification completionHandler:completionHandler];

        expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass.class);
        expect(stubActionHandler.notification.actionIdentifier).to.equal(actionIdentifier);
    });

    it(@"should not retain handlers", ^{
        RACSignal *willDealloc;
        @autoreleasepool {
            AUTStubUserNotificationActionHandler *stubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
            [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:AUTUserNotification.class];
            willDealloc = stubActionHandler.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should gracefully fail when receiving notifications with handlers that have been deallocated", ^{
        Class notificationClass = AUTTestLocalUserNotification.class;

        RACSignal *willDealloc;
        @autoreleasepool {
            AUTStubUserNotificationActionHandler *stubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
            [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];
            willDealloc = stubActionHandler.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();

        RACSignal *replayedActionCompleted = [actionCompleted replay];

        AUTTestLocalUserNotification *notification = [[notificationClass alloc] init];
        UILocalNotification *systemNotification = [notification createSystemNotification];
        [stubNotifier performActionWithIdentifier:actionIdentifier forLocalNotification:systemNotification completionHandler:completionHandler];

        expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should remove the handler upon disposal", ^{
        __block NSInteger invocations = 0;
        stubActionHandler.actionHandler = [[RACSignal empty] doCompleted:^{
            invocations++;
        }];

        RACDisposable *disposable = [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:AUTUserNotification.class];
        [disposable dispose];

        RACSignal *replayedActionCompleted = [actionCompleted replay];

        NSDictionary *notification = [AUTTestChildRemoteUserNotification asJSONDictionary];
        [stubNotifier performActionWithIdentifier:actionIdentifier forRemoteNotification:notification completionHandler:completionHandler];

        expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(invocations).to.equal(0);
    });

    describe(@"multiple handlers", ^{
        __block AUTStubUserNotificationActionHandler *anotherStubActionHandler;

        beforeEach(^{
            anotherStubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
        });

        it(@"should subscribe to the returned action handler signal for each registered handler", ^{
            __block NSInteger invocations = 0;
            RACSignal *actionHandler = [[RACSignal empty] doCompleted:^{
                invocations++;
            }];

            stubActionHandler.actionHandler = actionHandler;
            anotherStubActionHandler.actionHandler = actionHandler;

            Class notificationClass = AUTTestChildRemoteUserNotification.class;
            [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];
            [viewModel registerActionHandler:anotherStubActionHandler forNotificationsOfClass:notificationClass];

            RACSignal *replayedActionCompleted = [actionCompleted replay];

            NSDictionary *notification = [notificationClass asJSONDictionary];
            [stubNotifier performActionWithIdentifier:actionIdentifier forRemoteNotification:notification completionHandler:completionHandler];

            expect([replayedActionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
            expect(error).to.beNil();

            expect(invocations).to.equal(2);
            
            expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass.class);
            expect(stubActionHandler.notification.actionIdentifier).to.equal(actionIdentifier);
            expect(anotherStubActionHandler.notification).to.beAnInstanceOf(notificationClass.class);
            expect(anotherStubActionHandler.notification.actionIdentifier).to.equal(actionIdentifier);
        });
    });
});

describe(@"-scheduledLocalNotifications", ^{
    it(@"should send all scheduled notifications", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        AUTTestLocalUserNotification *anotherNotification = [[AUTTestLocalUserNotification alloc] init];

        notification.fireDate = [NSDate distantFuture];
        anotherNotification.fireDate = [NSDate distantFuture];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        NSArray *scheduledNotifications = [[[viewModel scheduledLocalNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(scheduledNotifications).to.haveACountOf(2);
        expect(scheduledNotifications).to.contain(notification);
        expect(scheduledNotifications).to.contain(anotherNotification);
    });
});

describe(@"-scheduledLocalNotificationsOfClass:", ^{
    it(@"should send only the scheduled notifications of the specified class", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        AUTTestLocalUserNotificationSubclass *anotherNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];

        notification.fireDate = [NSDate distantFuture];
        anotherNotification.fireDate = [NSDate distantFuture];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        NSArray *scheduledNotifications = [[[viewModel scheduledLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(scheduledNotifications).to.haveACountOf(1);
        expect(scheduledNotifications).notTo.contain(notification);
        expect(scheduledNotifications).to.contain(anotherNotification);
    });
});

describe(@"-scheduleLocalNotification:", ^{
    it(@"should schedule a local notification", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];

        RACSignal *receivedNotifications = [[viewModel receivedNotificationsOfClass:AUTLocalUserNotification.class]
            replay];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        AUTTestLocalUserNotification *receivedNotification = [receivedNotifications asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(receivedNotification).to.beKindOf(AUTTestLocalUserNotification.class);
        expect(receivedNotification).to.equal(notification);
        expect(receivedNotification).notTo.beIdenticalTo(notification);
    });
});

describe(@"-cancelLocalNotificationsOfClass:", ^{
    it(@"should only cancel scheduled notifications of the specified class", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        AUTTestLocalUserNotificationSubclass *anotherNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];

        notification.fireDate = [NSDate distantFuture];
        anotherNotification.fireDate = [NSDate distantFuture];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel cancelLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        NSArray *scheduledNotifications = [[[viewModel scheduledLocalNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(scheduledNotifications).to.haveACountOf(1);
        expect(scheduledNotifications).to.contain(notification);
        expect(scheduledNotifications).notTo.contain(anotherNotification);
    });
});

describe(@"-cancelScheduledLocalNotificationsOfClass:passingTest:", ^{
    it(@"should only cancel scheduled notifications of the specified class", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        notification.fireDate = [NSDate distantFuture];

        AUTTestLocalUserNotificationSubclass *distantFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        distantFutureNotification.fireDate = [NSDate distantFuture];

        AUTTestLocalUserNotificationSubclass *nearFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        nearFutureNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:10.0];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:distantFutureNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:nearFutureNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        RACSignal *cancelNearFutureNotifications = [viewModel
            cancelLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class
            passingTest:^ BOOL (AUTTestLocalUserNotificationSubclass * notification) {
                return notification.fireDate.timeIntervalSinceNow < 100.0;
            }];

        expect([cancelNearFutureNotifications asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        NSArray *scheduledNotifications = [[[viewModel scheduledLocalNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(scheduledNotifications).to.haveACountOf(2);
        expect(scheduledNotifications).to.contain(notification);
        expect(scheduledNotifications).to.contain(distantFutureNotification);
        expect(scheduledNotifications).notTo.contain(nearFutureNotification);
    });
});


SpecEnd
