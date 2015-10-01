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

/// Internally readwrite version of public readonly property.
///
/// If no action was invoked on the notification, this identifier is nil.
@property (readwrite, atomic, copy, nullable) NSString *actionIdentifier;

/// For an action performed on a notification, stores the block that should be
/// executed when finished performing the behavior caused by the action, as
/// provided by the system.
///
/// Consumers are not expected to invoke this block directly. It is internally
/// invoked by AUTUserNotificationsViewModel once the signal returned by each
/// registered action hander has completed.
///
/// Populated when the actionIdentifier property is populated.
///
/// AUTUserNotificationsViewModel sets this property to nil following its 
/// execution.
@property (readwrite, atomic, copy, nullable) void (^systemActionCompletionHandler)();

@end

NS_ASSUME_NONNULL_END
