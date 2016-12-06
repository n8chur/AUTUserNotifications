//
//  AUTUserNotificationsViewModel+Stubs.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/5/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotificationsViewModel_Private.h>
#import <AUTUserNotifications/AUTStubUserNotificationsApplication.h>
#import <AUTUserNotifications/AUTStubUserNotificationsAppDelegate.h>
#import <AUTUserNotifications/AUTStubUserNotificationCenter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTUserNotificationsViewModel (Stubs)

/// Creates a view model with a stub application, app delegate, notification
/// center, and the provided root remote notification class and default
/// presentation options.
+ (instancetype)stubViewModelWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions;

@end

NS_ASSUME_NONNULL_END
