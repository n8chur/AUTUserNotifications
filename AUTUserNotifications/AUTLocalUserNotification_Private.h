//
//  AUTLocalUserNotification_Private.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

#import <AUTUserNotifications/AUTLocalUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTLocalUserNotification ()

/// The notification that the receiver was created from, if there was one.
///
/// Typically populated in the case of the receiver being restored from a
/// received or enqueued notification.
///
/// Nil if the receiver was not created from a system notification.
@property (readwrite, atomic, strong, nullable) UILocalNotification *systemNotification;

/// Creates a local notification from a received system notification.
///
/// @param actionIdentifier The action identifier for the notification, if there
///        is one.
///
/// @param systemActionCompletionHandler The action completion handler for the
///        notification, if there is one.
///
/// @return nil if a notification should not be created from the specified
///         system local notification.
+ (nullable instancetype)notificationRestoredFromSystemNotification:(UILocalNotification *)systemNotification withActionIdentifier:(nullable NSString *)actionIdentifier systemActionCompletionHandler:(nullable void (^)())systemActionCompletionHandler;

@end

NS_ASSUME_NONNULL_END
