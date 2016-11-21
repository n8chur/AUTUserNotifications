//
//  AUTStubUserNotifier.m
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTStubUserNotifier.h"
#import "AUTStubUserNotificationHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotifier ()

@property (readonly, nonatomic, strong) id<AUTUserNotificationHandler> handler;

@property (readwrite, nonatomic, strong, nullable) UIUserNotificationSettings *currentUserNotificationSettings;

@end

@implementation AUTStubUserNotifier

#pragma mark - Lifecycle

- (instancetype)initWithHandler:(id<AUTUserNotificationHandler>)handler {
    NSParameterAssert(handler != nil);

    self = [super init];
    if (self == nil) return nil;

    _handler = handler;
    _scheduledLocalNotifications = [NSMutableArray array];
    _applicationState = UIApplicationStateActive;


    return self;
}

#pragma mark - AUTStubUserNotifier <AUTUserNotifier>

@synthesize scheduledLocalNotifications = _scheduledLocalNotifications;
@synthesize isRegisteredForRemoteNotifications = _isRegisteredForRemoteNotifications;
@synthesize applicationState = _applicationState;

#pragma mark Display Settings

- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    NSParameterAssert(notificationSettings != nil);

    self.currentUserNotificationSettings = notificationSettings;

    [self.handler
        application:(UIApplication *)NSObject.new
        didRegisterUserNotificationSettings:notificationSettings];
}

#pragma mark - Remote Notification Registration

- (void)registerForRemoteNotifications {
    if (self.remoteNotificationRegistrationError != nil) {
        self.isRegisteredForRemoteNotifications = NO;

        [self.handler
            application:(UIApplication *)NSObject.new
            didFailToRegisterForRemoteNotificationsWithError:self.remoteNotificationRegistrationError];

    } else if (self.remoteNotificationRegistrationDeviceToken != nil) {
        self.isRegisteredForRemoteNotifications = YES;

        [self.handler
            application:(UIApplication *)NSObject.new
            didRegisterForRemoteNotificationsWithDeviceToken:self.remoteNotificationRegistrationDeviceToken];
    } else {
        NSString *reason = @"You must either set an error or token before registering for remote notifications";
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

- (void)unregisterForRemoteNotifications {
    self.isRegisteredForRemoteNotifications = NO;
}

#pragma mark - Local Notification Management

- (void)cancelAllLocalNotifications {
    [self.scheduledLocalNotifications removeAllObjects];
}

- (void)cancelLocalNotification:(UILocalNotification *)notification {
    NSParameterAssert(notification != nil);

    [self.scheduledLocalNotifications removeObject:notification];
}

- (void)presentLocalNotificationNow:(UILocalNotification *)notification {
    NSParameterAssert(notification != nil);

    [self.handler application:(UIApplication *)NSObject.new didReceiveLocalNotification:notification];
}

- (void)scheduleLocalNotification:(UILocalNotification *)notification {
    NSParameterAssert(notification != nil);
    NSParameterAssert(notification.fireDate != nil);

    [self.scheduledLocalNotifications addObject:notification];

    [RACScheduler.mainThreadScheduler after:notification.fireDate schedule:^{
        // If the notification was cancelled, do not send it.
        if (![self.scheduledLocalNotifications containsObject:notification]) return;

        [self.scheduledLocalNotifications removeObject:notification];

        [self.handler application:(UIApplication *)NSObject.new didReceiveLocalNotification:notification];
    }];
}

#pragma mark - Remote Notification Management

- (void)displayRemoteNotification:(NSDictionary *)remoteNotification {
    NSParameterAssert(remoteNotification != nil);

    [self.handler application:(UIApplication *)NSObject.new didReceiveRemoteNotification:remoteNotification];
}

- (void)sendSilentRemoteNotification:(NSDictionary *)remoteNotification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))fetchCompletionHandler {
    NSParameterAssert(remoteNotification != nil);
    NSParameterAssert(fetchCompletionHandler != nil);

    [self.handler application:(UIApplication *)NSObject.new didReceiveRemoteNotification:remoteNotification fetchCompletionHandler:fetchCompletionHandler];
}

#pragma mark - Performing Actions

- (void)performActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification completionHandler:(void (^)())completionHandler {
    [self.handler application:(UIApplication *)NSObject.new handleActionWithIdentifier:identifier forRemoteNotification:remoteNotification completionHandler:completionHandler];
}

- (void)performActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)localNotification completionHandler:(void (^)())completionHandler {
    [self.handler application:(UIApplication *)NSObject.new handleActionWithIdentifier:identifier forLocalNotification:localNotification completionHandler:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
