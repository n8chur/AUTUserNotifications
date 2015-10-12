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

/// An abstract base class representing a notification that is presented to the
/// user locally via an AUTUserNotificationsViewModel.
@interface AUTLocalUserNotification : AUTUserNotification <AUTUserNotificationAlertDisplayable>

/// Creates a local notification from a received system notification.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the notification that is restored from a system
/// UILocalNotification.
///
/// @return nil if a notification should not be created from the specified
///         system local notification.
+ (nullable instancetype)notificationFromSystemNotification:(UILocalNotification *)systemNotification;

/// The notification that the receiver was created from, if there was one.
///
/// Typically populated in the case of the receiver being restored from a
/// received or enqueued notification.
///
/// Nil if the receiver was not created from a system notification.
@property (readonly, atomic, strong, nullable) UILocalNotification *systemNotification;

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
