//
//  AUTLocalUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;

#import <AUTUserNotifications/AUTUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

/// An abstract base class representing a notification that is presented to the
/// user locally via an AUTUserNotificationsViewModel.
@interface AUTLocalUserNotification : AUTUserNotification

/// When a notification request is created for the receiver, this method is
/// invoked to build its content.
///
/// The default implementation creates a notification with the category
/// identifier populated with the result of +[AUTUserNotification
/// systemCategoryIdentifier], and the userInfo populated with the information
/// necessary to restore the receiver upon receipt.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the notification content that is created from the receiver.
///
/// @return The notification content, or nil if one could not be created and
///         request creation should fail. Upon return from this method, a copy
///         of the content is made, so subsequent mutations are not respected.
- (nullable UNMutableNotificationContent *)createNotificationContent;

/// When a notification request is created for the receiver, this method is
/// invoked to build its trigger.
///
/// By default, returns a non-repeating UNTimeIntervalNotificationTrigger with
/// an interval 0.1 seconds from now (immediately).
///
/// @return The notification trigger, or nil if one could not be created and
///         request creation should fail.
- (nullable UNNotificationTrigger *)createNotificationTrigger;

/// When a notification request is created for the receiver, this method is
/// invoked to build its identifier.
///
/// Defaults to a string NSUUID, preventing previous instances of this class
/// from being cancelled when a new instance is scheduled.
///
/// Consumers should override this method to provide a unique identifier to
/// enable automatic cancellation behavior. From the UNNotificationRequest docs:
///
/// > If you use the same identifier when scheduling a new notification, the
/// > system removes the previously scheduled notification with that identifier
/// > and replaces it with the new one.
///
/// @return The notification identifier, or nil if one could not be created and
///         request creation should fail.
- (nullable NSString *)createNotificationIdentifier;

@end

NS_ASSUME_NONNULL_END
