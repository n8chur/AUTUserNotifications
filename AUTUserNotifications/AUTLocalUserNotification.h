//
//  AUTLocalUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotification.h>
#import <AUTUserNotifications/AUTUserNotificationAlertDisplayable.h>

NS_ASSUME_NONNULL_BEGIN

/// The key used to store an NSKeyedArchiver NSData representation of an
/// AUTLocalUserNotification within the userInfo of a UILocalNotification.
extern NSString * const AUTLocalUserNotificationKey;

/// An abstract base class representing a notification that is presented to the
/// user locally via an AUTUserNotificationsViewModel.
@interface AUTLocalUserNotification : AUTUserNotification <AUTUserNotificationAlertDisplayable>

/// Restores attributes on the receiver from a received system notification.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the notification that is restored from a system notification.
///
/// If the notification was received with an action identifier, it will be
/// populated as the actionIdentifier property on the receiver prior to invoking
/// this method.
///
/// @return NO if the receiver could should not be restored from the specified
///         system local notification.
- (BOOL)restoreFromSystemNotification:(UILocalNotification *)notification;

/// Creates a local notification representing the receiver to be sent to the
/// system.
///
/// The returned notification should be considered a copy. Its attributes will
/// not be updated in sync with the receiver following its creation.
///
/// If a system notification could not be created, returns nil.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the system notification that is created from the receiver.
- (nullable UILocalNotification *)createSystemNotification;

@end

NS_ASSUME_NONNULL_END
