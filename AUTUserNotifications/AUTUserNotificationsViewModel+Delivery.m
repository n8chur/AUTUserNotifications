//
//  AUTUserNotificationsViewModel+Delivery.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/2/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTUserNotification_Private.h"
#import "AUTExtObjC.h"
#import "AUTLog.h"
#import "AUTUserNotificationCenter.h"

#import "AUTUserNotificationsViewModel_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotificationsViewModel (Delivery)

#pragma mark - Public

- (RACSignal<__kindof AUTUserNotification *> *)deliveredNotifications {
    @weakify(self);
    RACSignal<NSArray<UNNotification *> *> *deliveredNotifications = [RACSignal createSignal:^RACDisposable * _Nullable (id<RACSubscriber>subscriber) {
        @strongifyOr(self) {
            [subscriber sendCompleted];
            return nil;
        }

        [self.center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
            [subscriber sendNext:notifications];
            [subscriber sendCompleted];
        }];

        return nil;
    }];

    return [[[deliveredNotifications
        flattenMap:^(NSArray<UNNotification *> *notifications) {
            return [notifications.rac_sequence signalWithScheduler:RACScheduler.immediateScheduler];
        }]
        map:^(UNNotification *notification) {
            return [AUTUserNotification
                notificationRestoredFromRequest:notification.request
                rootRemoteNotificationClass:self.rootRemoteNotificationClass];
        }]
        ignore:nil];
}

- (RACSignal<AUTUserNotification *> *)deliveredNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTUserNotification.class]);

    return [[self deliveredNotifications]
        filter:^(__kindof AUTUserNotification *notification) {
            return [notification isKindOfClass:notificationClass];
        }];
}

- (RACSignal *)removeDeliveredNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    let notifications = [self deliveredNotificationsOfClass:notificationClass];

    return [self removeDeliveredNotifications:notifications];
}

- (RACSignal *)removeDeliveredNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTUserNotification *))testBlock {
    AUTAssertNotNil(notificationClass, testBlock);

    let notifications = [[self deliveredNotificationsOfClass:notificationClass]
        filter:testBlock];

    return [self removeDeliveredNotifications:notifications];
}

#pragma mark - Private

- (RACSignal *)removeDeliveredNotifications:(RACSignal<__kindof AUTUserNotification *> *)notifications {
    AUTAssertNotNil(notifications);

    @weakify(self);

    return [[[[[[notifications
        doNext:^(__kindof AUTUserNotification *notification) {
            AUTLogUserNotificationInfo(@"%@ removing delivered notification: %@ ", self_weak_, notification);
        }]
        map:^(__kindof AUTUserNotification *notification) {
            return notification.request.identifier;
        }]
        ignore:nil]
        collect]
        doNext:^(NSArray<NSString *> *identifiers) {
            @strongify(self);
            if (self == nil || identifiers.count == 0) return;

            [self.center removeDeliveredNotificationsWithIdentifiers:identifiers];
        }]
        ignoreValues];
}

@end

NS_ASSUME_NONNULL_END
