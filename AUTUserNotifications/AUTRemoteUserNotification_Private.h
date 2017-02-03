//
//  AUTRemoteUserNotification_Private.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTRemoteUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTRemoteUserNotification ()

/// Attempts to restore a remote notification from the provided dictionary.
///
/// @return The successfully restored notification, otherwise nil if
///         unsuccessful.
+ (nullable __kindof AUTRemoteUserNotification *)notificationRestoredFromDictionary:(NSDictionary *)dictionary;

/// For a silent notification, stores the block that should be executed upon
/// fetch completion as provided by a system callback.
///
/// Consumers are not expected to invoke this block directly. It is internally
/// invoked by AUTUserNotificationsViewModel once the signal returned by each
/// registered fetch handler has completed.
///
/// AUTUserNotificationsViewModel sets this property to nil following its 
/// execution.
///
/// This property is not considered for equality checks nor included if the
/// receiver is archived.
@property (readwrite, atomic, copy, nullable) void (^systemFetchCompletionHandler)(UIBackgroundFetchResult);

@end

NS_ASSUME_NONNULL_END
