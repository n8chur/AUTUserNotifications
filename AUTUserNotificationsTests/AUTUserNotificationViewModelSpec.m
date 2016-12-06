//
//  AUTUserNotificationsViewModelSpec.m
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <AUTUserNotifications/AUTUserNotifications.h>
#import <AUTUserNotifications/AUTLocalUserNotification_Private.h>
#import <AUTUserNotifications/AUTUserNotificationsViewModel+Stubs.h>

#import "AUTStubRemoteNotificationRegistrar.h"
#import "AUTStubRemoteNotificationFetchHandler.h"
#import "AUTStubUserNotificationActionHandler.h"
#import "AUTTestLocalUserNotification.h"
#import "AUTTestRootRemoteUserNotification.h"
#import "AUTTestChildRemoteUserNotification.h"
#import "AUTAnotherTestChildRemoteUserNotification.h"

#import "AUTExtObjC.h"

SpecBegin(AUTUserNotificationsViewModel)

__block NSError *error;
__block BOOL success;

__block AUTStubUserNotificationsAppDelegate *stubAppDelegate;
__block AUTStubUserNotificationsApplication *stubApplication;
__block AUTStubUserNotificationCenter *stubCenter;
__block AUTStubRemoteNotificationRegistrar *stubRegistrar;
__block AUTUserNotificationsViewModel *viewModel;

let DefaultPresentationOptions = UNNotificationPresentationOptionSound;

beforeEach(^{
    error = nil;
    success = NO;

    stubAppDelegate = [[AUTStubUserNotificationsAppDelegate alloc] init];
    stubApplication = [[AUTStubUserNotificationsApplication alloc] initWithDelegate:stubAppDelegate];
    stubCenter = [[AUTStubUserNotificationCenter alloc] init];
    stubRegistrar = [[AUTStubRemoteNotificationRegistrar alloc] init];

    viewModel = [[AUTUserNotificationsViewModel alloc]
        initWithCenter:stubCenter
        application:stubApplication
        appDelegate:stubAppDelegate
        rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class
        defaultPresentationOptions:DefaultPresentationOptions];
});

describe(@"lifecycle", ^{
    it(@"should deallocate", ^{
        RACSignal *willDealloc;
        @autoreleasepool {
            let viewModel = [[AUTUserNotificationsViewModel alloc]
                initWithCenter:stubCenter
                application:stubApplication
                appDelegate:stubAppDelegate
                rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class
                defaultPresentationOptions:DefaultPresentationOptions];

            willDealloc = viewModel.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();
    });
});

describe(@"-requestAuthorization", ^{
    it(@"should request authorization", ^{
        let options = @(UNAuthorizationOptionSound | UNAuthorizationOptionAlert);

        stubCenter.settings = (UNNotificationSettings *)NSObject.new;

        stubCenter.authorizationGranted = YES;

        let registeredSettings = [[viewModel.requestAuthorization execute:options]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(registeredSettings).to.beIdenticalTo(stubCenter.settings);
        expect(error).to.beNil();
        expect(success).to.beTruthy();
    });

    it(@"should fail with an authorization error", ^{
        let options = @(UNAuthorizationOptionSound | UNAuthorizationOptionAlert);

        stubCenter.authorizationError = [NSError errorWithDomain:@"Test" code:-1 userInfo:nil];

        let registeredSettings = [[viewModel.requestAuthorization execute:options]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(registeredSettings).to.beNil();
        expect(error).to.beIdenticalTo(stubCenter.authorizationError);
        expect(success).to.beFalsy();
    });
});

describe(@"-registerForRemoteNotificationsCommand", ^{
    it(@"should perform registration with the registrar", ^{
        NSData *token = [@"token" dataUsingEncoding:NSUTF8StringEncoding];

        // Provide the token to the stubbed center
        stubApplication.remoteNotificationRegistrationDeviceToken = token;

        success = [[viewModel.registerForRemoteNotifications execute:stubRegistrar]
            asynchronouslyWaitUntilCompleted:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(stubRegistrar.registeredDeviceToken).to.beIdenticalTo(token);
    });

    it(@"should error if a failure occurs", ^{
        stubApplication.remoteNotificationRegistrationError = [NSError errorWithDomain:@"Test" code:-1 userInfo:nil];

        success = [[viewModel.registerForRemoteNotifications execute:stubRegistrar]
            asynchronouslyWaitUntilCompleted:&error];

        expect(success).to.beFalsy();
        expect(error).to.beIdenticalTo(stubApplication.remoteNotificationRegistrationError);
        expect(stubRegistrar.registeredDeviceToken).to.beNil();
    });
});

describe(@"-presentedNotifications", ^{
    describe(@"local notifications", ^{
        it(@"should receive local notifications", ^{
            let localNotification = [[AUTTestLocalUserNotification alloc] init];

            let presented = [viewModel.presentedNotifications replay];

            let request = [localNotification createNotificationRequest];
            let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];

            let presentationOption = [[stubCenter presentNotification:notification]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            let receivedNotification = [[presented take:1] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.equal(localNotification);
        });
    });

    describe(@"remote notifications", ^{
        it(@"should receive remote notifications", ^{
            Class notificationClass = AUTTestRootRemoteUserNotification.class;

            let presented = [viewModel.presentedNotifications replay];

            let presentationOption = [[stubCenter presentNotification:[notificationClass asStubNotification]]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            let receivedNotification = [[presented take:1] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.beAnInstanceOf(notificationClass.class);
        });
    });
});

describe(@"-presentedNotificationsOfClass:", ^{
    describe(@"local notifications", ^{
        it(@"should receive filtered local notifications", ^{
            let notificationSubclass = [[AUTTestLocalUserNotification alloc] init];
            let notificationSuperclass = [[AUTLocalUserNotification alloc] init];

            let presentedSubclasses = [[viewModel presentedNotificationsOfClass:notificationSubclass.class]
                replay];

            var request = [notificationSuperclass createNotificationRequest];
            var notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];

            var presentationOption = [[stubCenter presentNotification:notification]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            request = [notificationSubclass createNotificationRequest];
            notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];

            presentationOption = [[stubCenter presentNotification:notification]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            let receivedNotification = [[presentedSubclasses take:1] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.beAnInstanceOf(notificationSubclass.class);
            expect(receivedNotification).to.equal(notificationSubclass);
            expect(receivedNotification).notTo.beIdenticalTo(notificationSubclass);
        });
    });

    describe(@"remote notifications", ^{
        it(@"should receive filtered remote notifications", ^{
            Class notificationSubclass = AUTTestChildRemoteUserNotification.class;
            Class notificationSuperclass = AUTTestRootRemoteUserNotification.class;

            let receivedSubclasses = [[viewModel presentedNotificationsOfClass:notificationSubclass]
                replay];

            var presentationOption = [[stubCenter presentNotification:[notificationSubclass asStubNotification]]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            presentationOption = [[stubCenter presentNotification:[notificationSuperclass asStubNotification]]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            let receivedNotification = [[receivedSubclasses take:1] asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(receivedNotification).to.beAnInstanceOf(notificationSubclass.class);
        });
    });
});

describe(@"addPresentationOverride:", ^{
    it(@"should override presentation options while the handler is added", ^{
        Class notificationSubclass = AUTTestChildRemoteUserNotification.class;
        Class notificationSuperclass = AUTTestRootRemoteUserNotification.class;

        var presentationOption = [[stubCenter presentNotification:[notificationSubclass asStubNotification]]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(presentationOption).to.equal(DefaultPresentationOptions);
        expect(error).to.beNil();
        expect(success).to.beTruthy();

        let overridePresentationOptions = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;

        [viewModel addPresentationOverride:^(__kindof AUTUserNotification *notification) {
            return [notification isKindOfClass:notificationSubclass] ? @(overridePresentationOptions) : nil;
        }];

        presentationOption = [[stubCenter presentNotification:[notificationSuperclass asStubNotification]]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(presentationOption).to.equal(DefaultPresentationOptions);
        expect(error).to.beNil();
        expect(success).to.beTruthy();

        presentationOption = [[stubCenter presentNotification:[notificationSubclass asStubNotification]]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(presentationOption).to.equal(overridePresentationOptions);
        expect(error).to.beNil();
        expect(success).to.beTruthy();
    });

    it(@"should remove the override when the returned disposable is disposed", ^{
        it(@"should override presentation options while the handler is added", ^{
            Class notificationClass = AUTRemoteUserNotification.class;

            let overridePresentationOptions = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound;

            let disposable = [viewModel addPresentationOverride:^(__kindof AUTUserNotification *notification) {
                return [notification isKindOfClass:notificationClass] ? @(overridePresentationOptions) : nil;
            }];

            var presentationOption = [[stubCenter presentNotification:[notificationClass asStubNotification]]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(overridePresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();

            [disposable dispose];

            presentationOption = [[stubCenter presentNotification:[notificationClass asStubNotification]]
                asynchronousFirstOrDefault:nil success:&success error:&error];

            expect(presentationOption).to.equal(DefaultPresentationOptions);
            expect(error).to.beNil();
            expect(success).to.beTruthy();
        });
    });
});

describe(@"-registerFetchHandler:forRemoteUserNotificationsOfClass:", ^{
    __block AUTStubRemoteNotificationFetchHandler *stubFetchHandler;

    beforeEach(^{
        stubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
    });

    it(@"should indicate that no data was fetched when no fetch handlers are registered", ^{
        let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(UIBackgroundFetchResultNoData));
    });

    it(@"should execute the completion handler with the result of the fetch handler", ^{
        let fetchHandlerResult = UIBackgroundFetchResultNewData;
        stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

        [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

        let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
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

        let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(UIBackgroundFetchResultNoData));
    });

    it(@"should remove the handler upon disposal", ^{
        stubFetchHandler.fetchHandler = [RACSignal return:@(UIBackgroundFetchResultNoData)];

        let disposable = [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
        [disposable dispose];

        let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();

        expect(stubFetchHandler.notification).to.beNil();
    });

    it(@"should allow removing a specific class when a handler is registered for multiple classes", ^{
        let fetchHandlerResult = UIBackgroundFetchResultNoData;
        stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

        let childDisposable = [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
        [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTAnotherTestChildRemoteUserNotification.class];

        [childDisposable dispose];

        var notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        var fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        var systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(fetchHandlerResult));

        expect(stubFetchHandler.notification).to.beNil();

        notification = [AUTAnotherTestChildRemoteUserNotification asSilentJSONDictionary];
        fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(fetchHandlerResult));

        expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTAnotherTestChildRemoteUserNotification.class);
    });

    it(@"should invoke one handler registered for multiple notifications", ^{
        let fetchHandlerResult = UIBackgroundFetchResultNoData;
        stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

        [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
        [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTAnotherTestChildRemoteUserNotification.class];

        var notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
        var fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        var systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(fetchHandlerResult));

        expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);

        notification = [AUTAnotherTestChildRemoteUserNotification asSilentJSONDictionary];
        fetchResult = [stubApplication sendSilentRemoteNotification:notification];

        systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(systemResult).notTo.beNil();
        expect(systemResult).to.equal(@(fetchHandlerResult));

        expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTAnotherTestChildRemoteUserNotification.class);
    });

    describe(@"multiple handlers", ^{
        __block AUTStubRemoteNotificationFetchHandler *anotherStubFetchHandler;

        beforeEach(^{
            anotherStubFetchHandler = [[AUTStubRemoteNotificationFetchHandler alloc] init];
        });

        it(@"should execute the completion handler with the worst handler result", ^{
            let fetchHandlerResult = UIBackgroundFetchResultNoData;
            stubFetchHandler.fetchHandler = [RACSignal return:@(fetchHandlerResult)];

            // Failure is worse than "no data".
            let anotherFetchHandlerResult = UIBackgroundFetchResultFailed;
            anotherStubFetchHandler.fetchHandler = [RACSignal return:@(anotherFetchHandlerResult)];

            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            [viewModel registerFetchHandler:anotherStubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

            let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
            let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

            let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(systemResult).notTo.beNil();
            expect(systemResult).to.equal(@(anotherFetchHandlerResult));

            expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
            expect(anotherStubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
        });

        it(@"should subscribe to the returned fetch handler signal for each registered handler", ^{
            stubFetchHandler.fetchHandler = [RACSignal return:@(UIBackgroundFetchResultNoData)];
            anotherStubFetchHandler.fetchHandler = [RACSignal return:@(UIBackgroundFetchResultNoData)];

            [viewModel registerFetchHandler:stubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];
            [viewModel registerFetchHandler:anotherStubFetchHandler forRemoteUserNotificationsOfClass:AUTTestChildRemoteUserNotification.class];

            let notification = [AUTTestChildRemoteUserNotification asSilentJSONDictionary];
            let fetchResult = [stubApplication sendSilentRemoteNotification:notification];

            let systemResult = [fetchResult asynchronousFirstOrDefault:nil success:&success error:&error];
            expect(error).to.beNil();
            expect(success).to.beTruthy();
            expect(systemResult).notTo.beNil();

            expect(stubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
            expect(anotherStubFetchHandler.notification).to.beAnInstanceOf(AUTTestChildRemoteUserNotification.class);
        });
    });
});

describe(@"registerActionHandler:forNotificationsOfClass:", ^{
    __block AUTStubUserNotificationActionHandler *stubActionHandler;

    let actionIdentifier = @"an action";

    beforeEach(^{
        stubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
    });

    it(@"should invoke the action completion handler when no action handlers are registered", ^{
        let response = [AUTTestChildRemoteUserNotification asStubResponseWithActionIdentifier:actionIdentifier];
        let actionCompleted = [stubCenter receiveNotification:response];

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should invoke the action completion handler after invoking the registered action handler for a remote notification", ^{
        let notificationClass = AUTTestChildRemoteUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];

        let response = [notificationClass asStubResponseWithActionIdentifier:actionIdentifier];
        let actionCompleted = [stubCenter receiveNotification:response];
        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass);
        expect(stubActionHandler.notification.response).to.beIdenticalTo(response);
    });

    it(@"should invoke the action completion handler after invoking the registered action handler for a local notification", ^{
        Class notificationClass = AUTTestLocalUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];

        AUTTestLocalUserNotification *localNotification = [[notificationClass alloc] init];
        let request = [localNotification createNotificationRequest];
        let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
        let response = [[AUTStubUNNotificationResponse alloc] initWithNotification:notification actionIdentifier:actionIdentifier];

        let actionCompleted = [stubCenter receiveNotification:response];
        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass);
        expect(stubActionHandler.notification.response).to.beIdenticalTo(response);
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

    it(@"should invoke one handler registered for multiple notifications", ^{
        stubActionHandler.actionHandler = [RACSignal empty];

        let remoteNotificationClass = AUTTestChildRemoteUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:remoteNotificationClass];

        let localNotificationClass = AUTTestLocalUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:localNotificationClass];

        var response = [remoteNotificationClass asStubResponseWithActionIdentifier:actionIdentifier];
        var actionCompleted = [stubCenter receiveNotification:response];

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(remoteNotificationClass);
        expect(stubActionHandler.notification.response).to.beIdenticalTo(response);

        AUTTestLocalUserNotification *localNotification = [[localNotificationClass alloc] init];
        let request = [localNotification createNotificationRequest];
        let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
        response = [[AUTStubUNNotificationResponse alloc] initWithNotification:notification actionIdentifier:actionIdentifier];
        actionCompleted = [stubCenter receiveNotification:response];

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(localNotificationClass);
        expect(stubActionHandler.notification.response).to.beIdenticalTo(response);
    });

    it(@"should gracefully fail when receiving notifications with handlers that have been deallocated", ^{
        let notificationClass = AUTTestLocalUserNotification.class;

        RACSignal *willDealloc;
        @autoreleasepool {
            let stubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
            [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];
            willDealloc = stubActionHandler.rac_willDeallocSignal;
        }
        success = [willDealloc asynchronouslyWaitUntilCompleted:&error];
        expect(success).to.beTruthy();
        expect(error).to.beNil();

        AUTTestLocalUserNotification *localNotification = [[notificationClass alloc] init];
        let request = [localNotification createNotificationRequest];
        let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
        let response = [[AUTStubUNNotificationResponse alloc] initWithNotification:notification actionIdentifier:actionIdentifier];
        let actionCompleted = [stubCenter receiveNotification:response];

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();
    });

    it(@"should remove the handler upon disposal", ^{
        stubActionHandler.actionHandler = [RACSignal empty];

        let disposable = [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:AUTUserNotification.class];
        [disposable dispose];

        let response = [AUTTestChildRemoteUserNotification asStubResponseWithActionIdentifier:actionIdentifier];
        let actionCompleted = [stubCenter receiveNotification:response];
        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beNil();
    });

    it(@"should allow removing a specific class when a handler is registered for multiple classes", ^{
        stubActionHandler.actionHandler = [RACSignal empty];

        let remoteNotificationClass = AUTTestChildRemoteUserNotification.class;
        let remoteNotificationClassDisposable = [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:remoteNotificationClass];

        let localNotificationClass = AUTTestLocalUserNotification.class;
        [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:localNotificationClass];

        [remoteNotificationClassDisposable dispose];

        var response = [remoteNotificationClass asStubResponseWithActionIdentifier:actionIdentifier];
        var actionCompleted = [stubCenter receiveNotification:response];
        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beNil();

        AUTTestLocalUserNotification *localNotification = [[localNotificationClass alloc] init];
        let request = [localNotification createNotificationRequest];
        let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
        response = [[AUTStubUNNotificationResponse alloc] initWithNotification:notification actionIdentifier:actionIdentifier];
        actionCompleted = [stubCenter receiveNotification:response];

        expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect(stubActionHandler.notification).to.beAnInstanceOf(localNotificationClass);
        expect(stubActionHandler.notification.request).to.beIdenticalTo(request);
    });

    describe(@"multiple handlers", ^{
        __block AUTStubUserNotificationActionHandler *anotherStubActionHandler;

        beforeEach(^{
            anotherStubActionHandler = [[AUTStubUserNotificationActionHandler alloc] init];
        });

        it(@"should subscribe to the returned action handler signal for each registered handler", ^{
            stubActionHandler.actionHandler = [RACSignal empty];
            anotherStubActionHandler.actionHandler = [RACSignal empty];

            Class notificationClass = AUTTestChildRemoteUserNotification.class;
            [viewModel registerActionHandler:stubActionHandler forNotificationsOfClass:notificationClass];
            [viewModel registerActionHandler:anotherStubActionHandler forNotificationsOfClass:notificationClass];

            let response = [notificationClass asStubResponseWithActionIdentifier:actionIdentifier];
            let actionCompleted = [stubCenter receiveNotification:response];
            expect([actionCompleted asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
            expect(error).to.beNil();

            expect(stubActionHandler.notification).to.beAnInstanceOf(notificationClass.class);
            expect(stubActionHandler.notification.response).to.beIdenticalTo(response);

            expect(anotherStubActionHandler.notification).to.beAnInstanceOf(notificationClass.class);
            expect(anotherStubActionHandler.notification.response).to.beIdenticalTo(response);
        });
    });
});

describe(@"-scheduledLocalNotifications", ^{
    it(@"should send all scheduled notifications", ^{
        let notification = [[AUTTestLocalUserNotification alloc] init];
        let anotherNotification = [[AUTTestLocalUserNotification alloc] init];

        notification.triggerTimeInterval = 10.0;
        anotherNotification.triggerTimeInterval = 10.0;

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let scheduledNotifications = [[[viewModel scheduledLocalNotifications]
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
        let notification = [[AUTTestLocalUserNotification alloc] init];
        let anotherNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];

        notification.triggerTimeInterval = 10.0;
        anotherNotification.triggerTimeInterval = 10.0;

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let scheduledNotifications = [[[viewModel scheduledLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class]
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
        let notification = [[AUTTestLocalUserNotification alloc] init];

        let presentedNotifications = [[viewModel presentedNotificationsOfClass:AUTLocalUserNotification.class]
            replay];

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let receivedNotification = [presentedNotifications asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(receivedNotification).to.beKindOf(AUTTestLocalUserNotification.class);
        expect(receivedNotification).to.equal(notification);
        expect(receivedNotification).notTo.beIdenticalTo(notification);
    });
});

describe(@"-unscheduleLocalNotificationsOfClass:", ^{
    it(@"should only cancel scheduled notifications of the specified class", ^{
        let notification = [[AUTTestLocalUserNotification alloc] init];
        let anotherNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];

        notification.triggerTimeInterval = 10.0;
        anotherNotification.triggerTimeInterval = 10.0;

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:anotherNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel unscheduleLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let scheduledNotifications = [[[viewModel scheduledLocalNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(scheduledNotifications).to.haveACountOf(1);
        expect(scheduledNotifications).to.contain(notification);
        expect(scheduledNotifications).notTo.contain(anotherNotification);
    });
});

describe(@"-unscheduleLocalNotificationsOfClass:passingTest:", ^{
    it(@"should only cancel scheduled notifications of the specified class that pass the given test", ^{
        let notification = [[AUTTestLocalUserNotification alloc] init];
        notification.triggerTimeInterval = 10.0;

        let distantFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        distantFutureNotification.triggerTimeInterval = 1000.0;

        AUTTestLocalUserNotificationSubclass *nearFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        nearFutureNotification.triggerTimeInterval = 10.0;

        expect([[viewModel scheduleLocalNotification:notification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:distantFutureNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        expect([[viewModel scheduleLocalNotification:nearFutureNotification] asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let unscheduleNearFutureNotifications = [viewModel
            unscheduleLocalNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class
            passingTest:^ BOOL (AUTTestLocalUserNotificationSubclass * notification) {
                return ((UNTimeIntervalNotificationTrigger *)notification.request.trigger).timeInterval < 100.0;
            }];

        expect([unscheduleNearFutureNotifications asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
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

describe(@"-deliveredNotifications", ^{
    it(@"should send all delivered notifications", ^{
        let localNotification = [[AUTTestLocalUserNotification alloc] init];
        let stubRequest = [localNotification createNotificationRequest];
        let stubLocalNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:stubRequest];

        let remoteNotification = [[AUTTestRootRemoteUserNotification alloc] init];
        var stubRemoteNotification = [AUTTestRootRemoteUserNotification asStubNotification];

        stubCenter.deliveredNotifications = [@[ stubLocalNotification, stubRemoteNotification ] mutableCopy];

        let deliveredNotifications = [[[viewModel deliveredNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(deliveredNotifications).to.haveACountOf(2);
        expect(deliveredNotifications).to.contain(localNotification);
        expect(deliveredNotifications).to.contain(remoteNotification);
    });
});

describe(@"-deliveredNotificationsOfClass:", ^{
    it(@"should send only the delivered notifications of the specified class", ^{
        let localNotification = [[AUTTestLocalUserNotification alloc] init];
        let stubRequest = [localNotification createNotificationRequest];
        let stubLocalNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:stubRequest];

        let remoteNotification = [[AUTTestRootRemoteUserNotification alloc] init];
        var stubRemoteNotification = [AUTTestRootRemoteUserNotification asStubNotification];

        stubCenter.deliveredNotifications = [@[ stubLocalNotification, stubRemoteNotification ] mutableCopy];

        let deliveredNotifications = [[[viewModel deliveredNotificationsOfClass:AUTTestRootRemoteUserNotification.class]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(deliveredNotifications).to.haveACountOf(1);
        expect(deliveredNotifications).notTo.contain(localNotification);
        expect(deliveredNotifications).to.contain(remoteNotification);
    });
});

describe(@"-removeDeliveredNotificationsOfClass:", ^{
    it(@"should only remove delivered notifications of the specified class", ^{
        let localNotification = [[AUTTestLocalUserNotification alloc] init];
        let stubRequest = [localNotification createNotificationRequest];
        let stubLocalNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:stubRequest];

        let remoteNotification = [[AUTTestRootRemoteUserNotification alloc] init];
        let stubRemoteNotification = [AUTTestRootRemoteUserNotification asStubNotification];

        let anotherRemoteNotification = [[AUTTestChildRemoteUserNotification alloc] init];
        let anotherStubRemoteNotification = [AUTTestChildRemoteUserNotification asStubNotification];

        stubCenter.deliveredNotifications = [@[ stubLocalNotification, stubRemoteNotification, anotherStubRemoteNotification ] mutableCopy];

        success = [[viewModel removeDeliveredNotificationsOfClass:AUTTestChildRemoteUserNotification.class]
            asynchronouslyWaitUntilCompleted:&error];

        let deliveredNotifications = [[[viewModel deliveredNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(deliveredNotifications).to.haveACountOf(2);
        expect(deliveredNotifications).to.contain(localNotification);
        expect(deliveredNotifications).to.contain(remoteNotification);
        expect(deliveredNotifications).notTo.contain(anotherRemoteNotification);
    });
});

describe(@"-removeDelvieredNotificationsOfClass:passingTest:", ^{
    it(@"should only remove delivered notifications of the specified class that pass the given test", ^{
        let notification = [[AUTTestLocalUserNotification alloc] init];
        notification.triggerTimeInterval = 10.0;
        let stubRequest = [notification createNotificationRequest];
        let stubNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:stubRequest];

        let distantFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        distantFutureNotification.triggerTimeInterval = 1000.0;
        let distantFutureRequest = [distantFutureNotification createNotificationRequest];
        let stubDistantFutureNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:distantFutureRequest];

        let nearFutureNotification = [[AUTTestLocalUserNotificationSubclass alloc] init];
        nearFutureNotification.triggerTimeInterval = 10.0;
        let nearFutureRequest = [nearFutureNotification createNotificationRequest];
        let stubNearFutureNotification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:nearFutureRequest];

        stubCenter.deliveredNotifications = [@[ stubNotification, stubDistantFutureNotification, stubNearFutureNotification ] mutableCopy];

        let removeNearFutureNotifications = [viewModel
            removeDeliveredNotificationsOfClass:AUTTestLocalUserNotificationSubclass.class
            passingTest:^ BOOL (AUTTestLocalUserNotificationSubclass * notification) {
                return ((UNTimeIntervalNotificationTrigger *)notification.request.trigger).timeInterval < 100.0;
            }];

        expect([removeNearFutureNotifications asynchronouslyWaitUntilCompleted:&error]).to.beTruthy();
        expect(error).to.beNil();

        let deliveredNotifications = [[[viewModel deliveredNotifications]
            collect]
            asynchronousFirstOrDefault:nil success:&success error:&error];

        expect(error).to.beNil();
        expect(success).to.beTruthy();
        expect(deliveredNotifications).to.haveACountOf(2);
        expect(deliveredNotifications).to.contain(notification);
        expect(deliveredNotifications).to.contain(distantFutureNotification);
        expect(deliveredNotifications).notTo.contain(nearFutureNotification);
    });
});

SpecEnd
