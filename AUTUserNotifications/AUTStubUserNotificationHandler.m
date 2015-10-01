//
//  AUTStubUserNotificationHandler.m
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTStubUserNotificationHandler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTStubUserNotificationHandler

#pragma mark - Registration Callbacks

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {}

#pragma mark - Notification Receipt

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {}

#pragma mark - Fetch Handlers

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {}

#pragma mark - Action Handlers

- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler {}
- (void)application:(UIApplication *)application handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {}

@end

NS_ASSUME_NONNULL_END
