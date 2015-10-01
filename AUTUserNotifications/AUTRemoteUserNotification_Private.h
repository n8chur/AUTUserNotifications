//
//  AUTRemoteUserNotification_Private.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTRemoteUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTRemoteUserNotification ()

/// For a silent notification, stores the block that should be executed upon
/// fetch completion as provided by a system callback.
///
/// Consumers are not expected to invoke this block directly. It is internally
/// invoked by AUTUserNotificationsViewModel once the signal returned by each
/// registered fetch handler has completed.
///
/// AUTUserNotificationsViewModel sets this property to nil following its 
/// execution.
@property (readwrite, atomic, copy, nullable) void (^systemFetchCompletionHandler)(UIBackgroundFetchResult);

@end

NS_ASSUME_NONNULL_END
