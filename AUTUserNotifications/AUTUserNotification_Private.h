//
//  AUTUserNotification_Private.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

#import <AUTUserNotifications/AUTUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTUserNotification ()

@property (readwrite, nonatomic, nullable) UNNotificationResponse *response;
@property (readwrite, nonatomic, nullable) UNNotificationRequest *request;

/// Attempts to restore a notification from the provided request.
///
/// @return The successfully restored notification, otherwise nil if
///         unsuccessful.
+ (nullable __kindof AUTUserNotification *)notificationRestoredFromRequest:(UNNotificationRequest *)request rootRemoteNotificationClass:(Class)rootRemoteNotificationClass;

/// Attempts to restore a notification from the provided response.
///
/// @return The successfully restored notification, otherwise nil if
///         unsuccessful.
+ (nullable __kindof AUTUserNotification *)notificationRestoredFromResponse:(UNNotificationResponse *)response rootRemoteNotificationClass:(Class)rootRemoteNotificationClass completionHandler:(nullable void(^)())completionHandler;

/// Stores the block that should be executed following the completion of
/// handling the receiver, as provided by a system callback.
///
/// Consumers are not expected to invoke this block directly. It is internally
/// invoked by AUTUserNotificationsViewModel once the signal returned by each
/// registered fetch handler has completed.
///
/// AUTUserNotificationsViewModel sets this property to nil following its 
/// execution.
@property (readwrite, atomic, copy, nullable) void (^responseCompletionHandler)();

/// The user notification category for this class.
///
/// Subclasses do not need to override this method directly. Instead, they
/// should override systemCategoryIdentifier, systemCategoryOptions,
/// systemCategoryActions, and systemCategoryIntentIdentifiers, which
/// are invoked when calling this method to build the returned category.
///
/// @return nil if there are no actions for the specified category.
+ (nullable UNNotificationCategory *)systemCategory;

@end

NS_ASSUME_NONNULL_END
