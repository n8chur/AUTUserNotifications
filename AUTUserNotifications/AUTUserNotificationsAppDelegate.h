//
//  AUTUserNotificationsAppDelegate.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/// Describes the app delegate.
///
/// Matches methods on UIApplicationDelegate.
@protocol AUTUserNotificationsAppDelegate <NSObject>

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;

@end

NS_ASSUME_NONNULL_END
