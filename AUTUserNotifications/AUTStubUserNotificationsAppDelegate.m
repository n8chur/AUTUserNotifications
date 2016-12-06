//
//  AUTStubUserNotificationsAppDelegate.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTStubUserNotificationsAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTStubUserNotificationsAppDelegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {}
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {}

@end

NS_ASSUME_NONNULL_END
