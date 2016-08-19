//
//  AUTUserNotifier.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/// Describes a class that can register local and remote notifications settings
/// and schedule, cancel, and present local user notifications.
///
/// Matches methods on UIApplication.
@protocol AUTUserNotifier <NSObject>

#pragma mark - State

@property (readonly, nonatomic) UIApplicationState applicationState;

#pragma mark - Display Settings

- (void)registerUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
- (nullable UIUserNotificationSettings *)currentUserNotificationSettings;

#pragma mark - Remote Notification Registration

- (BOOL)isRegisteredForRemoteNotifications;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotifications;

#pragma mark - Local Notification Management

@property (nullable, nonatomic, copy) NSArray <UILocalNotification *> *scheduledLocalNotifications;

- (void)cancelAllLocalNotifications;
- (void)cancelLocalNotification:(UILocalNotification *)notification;
- (void)presentLocalNotificationNow:(UILocalNotification *)notification;
- (void)scheduleLocalNotification:(UILocalNotification *)notification;

@end

NS_ASSUME_NONNULL_END
