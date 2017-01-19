//
//  AUTStubUserNotificationCenter.m
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTExtObjC.h"

#import "AUTStubUserNotificationCenter.h"
#import "AUTStubUserNotificationsAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationCenter ()

@end

@implementation AUTStubUserNotificationCenter

- (instancetype)init {
    self = [super init];

    _notificationsRequests = [NSArray array];
    _deliveredNotifications = [NSArray array];
    _notificationCategories = [NSSet set];
    _settings = (UNNotificationSettings *)NSObject.new;

    return self;
}

@synthesize delegate;
@synthesize supportsContentExtensions;

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError * _Nullable error))completionHandler {
    self.requestedAuthorizationOptions = options;
    completionHandler(self.authorizationGranted, self.authorizationError);
}

- (void)getNotificationCategoriesWithCompletionHandler:(void (^)(NSSet<UNNotificationCategory *> *categories))completionHandler {
    completionHandler(self.notificationCategories);
}

- (void)getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings *settings))completionHandler {
    completionHandler(self.settings);
}

- (void)addNotificationRequest:(UNNotificationRequest *)request withCompletionHandler:(nullable void(^)(NSError * _Nullable error))completionHandler {
    self.notificationsRequests = [self.notificationsRequests arrayByAddingObject:request];

    if ([request.trigger isKindOfClass:UNTimeIntervalNotificationTrigger.class]) {
        let trigger = (UNTimeIntervalNotificationTrigger *)request.trigger;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(trigger.timeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            let notification = [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
            [self presentNotification:notification];
        });
    }

    if (completionHandler != nil) {
        completionHandler(nil);
    }
}

- (void)getPendingNotificationRequestsWithCompletionHandler:(void (^)(NSArray<UNNotificationRequest *> *requests))completionHandler {
    completionHandler(self.notificationsRequests);
}

- (void)removePendingNotificationRequestsWithIdentifiers:(NSArray<NSString *> *)identifiers {
    self.notificationsRequests = [[self.notificationsRequests.rac_sequence
        filter:^ BOOL (UNNotificationRequest *request) {
            return ![identifiers containsObject:request.identifier];
        }]
        array];
}

- (void)removeAllPendingNotificationRequests {
    self.notificationsRequests = @[];
}

- (void)getDeliveredNotificationsWithCompletionHandler:(void (^)(NSArray<UNNotification *> *notifications))completionHandler {
    completionHandler((NSArray<UNNotification *> *)self.deliveredNotifications);
}

- (void)removeDeliveredNotificationsWithIdentifiers:(NSArray<NSString *> *)identifiers {
    self.deliveredNotifications = [[self.deliveredNotifications.rac_sequence
        filter:^ BOOL (AUTStubUNNotification *notification) {
            return ![identifiers containsObject:notification.request.identifier];
        }]
        array];
}

- (void)removeAllDeliveredNotifications {
    self.deliveredNotifications = @[];
}

- (RACSignal<NSNumber *> *)presentNotification:(AUTStubUNNotification *)notification {
    RACSubject *subject = [RACReplaySubject subject];

    [self.delegate userNotificationCenter:(UNUserNotificationCenter *)self willPresentNotification:(UNNotification *)notification withCompletionHandler:^(UNNotificationPresentationOptions options) {
        [subject sendNext:@(options)];
        [subject sendCompleted];
    }];

    return subject;
}

- (RACSignal *)receiveNotification:(AUTStubUNNotificationResponse *)response {
    RACSubject *subject = [RACReplaySubject subject];

    [self.delegate userNotificationCenter:(UNUserNotificationCenter *)self didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:^{
        [subject sendCompleted];
    }];

    return subject;
}

@end

@implementation AUTStubUNNotification

- (instancetype)init AUT_UNAVAILABLE_DESIGNATED_INITIALIZER;

- (instancetype)initWithDate:(NSDate *)date request:(UNNotificationRequest *)request {
    AUTAssertNotNil(date, request);

    self = [super init];

    _date = [date copy];
    _request = request;

    return self;
}

@end

@implementation AUTStubUNNotificationResponse

- (instancetype)init AUT_UNAVAILABLE_DESIGNATED_INITIALIZER;

- (instancetype)initWithNotification:(AUTStubUNNotification *)notification actionIdentifier:(NSString *)actionIdentifier {
    AUTAssertNotNil(notification, actionIdentifier);

    self = [super init];

    _notification = notification;
    _actionIdentifier = [actionIdentifier copy];

    return self;
}

@end

NS_ASSUME_NONNULL_END
