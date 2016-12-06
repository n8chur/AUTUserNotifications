//
//  AUTUserNotificationsViewModel+Scheduling.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/2/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTLocalUserNotification_Private.h"
#import "AUTUserNotification_Private.h"
#import "AUTExtObjC.h"
#import "AUTLog.h"
#import "AUTUserNotificationCenter.h"

#import "AUTUserNotificationsViewModel_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotificationsViewModel (Scheduling)

#pragma mark - Public

- (RACSignal<__kindof AUTLocalUserNotification *> *)scheduledLocalNotifications {
    return [self scheduledLocalNotificationsOfClass:AUTLocalUserNotification.class];
}

- (RACSignal<__kindof AUTLocalUserNotification *> *)scheduledLocalNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTLocalUserNotification.class]);

    @weakify(self);

    RACSignal<NSArray<UNNotificationRequest *> *> *pendingRequests = [RACSignal createSignal:^RACDisposable * _Nullable (id<RACSubscriber>subscriber) {
        @strongifyOr(self) {
            [subscriber sendCompleted];
            return nil;
        }

        [self.center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
            [subscriber sendNext:requests];
            [subscriber sendCompleted];
        }];

        return nil;
    }];

    return [[[[pendingRequests
        flattenMap:^(NSArray<UNNotificationRequest *> *requests) {
            return [requests.rac_sequence signalWithScheduler:RACScheduler.immediateScheduler];
        }]
        map:^(UNNotificationRequest *request) {
            return [AUTUserNotification
                notificationRestoredFromRequest:request
                rootRemoteNotificationClass:self.rootRemoteNotificationClass];
        }]
        ignore:nil]
        filter:^(__kindof AUTUserNotification *notification) {
            return [notification isKindOfClass:notificationClass];
        }];
}

- (RACSignal *)scheduleLocalNotification:(AUTLocalUserNotification *)notification {
    AUTAssertNotNil(notification);

    @weakify(self);

    return [RACSignal defer:^{
        @strongifyOr(self) return [RACSignal empty];

        let request = [notification createNotificationRequest];
        if (request == nil) {
            AUTLogUserNotificationInfo(@"%@ not scheduling notification, unable to build request from  %@ ", self_weak_, notification);
            return [RACSignal empty];
        }

        return [RACSignal createSignal:^ RACDisposable * _Nullable (id<RACSubscriber> subscriber) {
            @strongifyOr(self) {
                [subscriber sendCompleted];
                return nil;
            }

            AUTLogUserNotificationInfo(@"%@ scheduling notification: %@ ", self_weak_, notification);

            [self.center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error != nil) {
                    AUTLogUserNotificationError(@"%@ failed to schedule notification %@ %@", self_weak_, notification, error);
                    [subscriber sendError:error];
                } else {
                    AUTLogUserNotificationInfo(@"%@ notification scheduled: %@ ", self_weak_, notification);
                    [subscriber sendCompleted];
                }
            }];

            return nil;
        }];
    }];
}

- (RACSignal *)unscheduleLocalNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    let notifications = [self scheduledLocalNotificationsOfClass:notificationClass];

    return [self unscheduleLocalNotifications:notifications];
}

- (RACSignal *)unscheduleLocalNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTLocalUserNotification *notification))testBlock {
    AUTAssertNotNil(notificationClass, testBlock);

    let notifications = [[self scheduledLocalNotificationsOfClass:notificationClass]
        filter:testBlock];

    return [self unscheduleLocalNotifications:notifications];
}

#pragma mark - Private

- (RACSignal *)unscheduleLocalNotifications:(RACSignal<__kindof AUTLocalUserNotification *> *)notifications {
    AUTAssertNotNil(notifications);

    @weakify(self);

    return [[[[[[notifications
        doNext:^(__kindof AUTLocalUserNotification *notification) {
            AUTLogUserNotificationInfo(@"%@ unscheduling local notification: %@ ", self_weak_, notification);
        }]
        map:^(__kindof AUTLocalUserNotification *notification) {
            return notification.request.identifier;
        }]
        ignore:nil]
        collect]
        doNext:^(NSArray<NSString *> *identifiers) {
            @strongify(self);
            if (self == nil || identifiers.count == 0) return;

            [self.center removePendingNotificationRequestsWithIdentifiers:identifiers];
        }]
        ignoreValues];
}

@end

NS_ASSUME_NONNULL_END
