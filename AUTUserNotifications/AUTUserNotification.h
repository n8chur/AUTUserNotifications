//
//  AUTUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Mantle;

NS_ASSUME_NONNULL_BEGIN

/// An abstract base class for remote or local notifications.
///
/// Inherits from MTLModel so that a notification can be archived for storage
/// in a system local notification between launches of the application, and so
/// that a remote notification's properties can be mapped from the JSON payload
/// of a remote notification.
@interface AUTUserNotification : MTLModel

/// If an action was performed on the receiver, populated with the identifier of
/// the action.
///
/// Subclasses are encouraged to expose an enumeration that wraps the values of
/// this string for consumer safety.
///
/// If no action was invoked on the notification, this identifier is nil.
@property (readonly, atomic, copy, nullable) NSString *actionIdentifier;

/// The category identifier for an instance of the receiver.
///
/// Defaults to a string representation of the class, using NSStringFromClass().
///
/// Subclasses may override this method to provide a custom category identifier.
/// This is required in the case of remote notifications.
+ (NSString *)systemCategoryIdentifier;

/// The user notification category for this class.
///
/// Subclasses do not need to override this method directly. Instead, they
/// should override systemActionsForContext: and systemCategoryIdentifier, which
/// are invoked when calling this method to build the returned category.
///
/// @return nil if there are no actions for the specified category.
+ (nullable UIUserNotificationCategory *)systemCategory;

/// The actions that are available on an instance of the receiver.
///
/// Subclasses should override this method to provide the actions available on
/// a notification of the receiver's class.
///
/// @return nil or an empty array if there are no actions.
+ (nullable NSArray<UIUserNotificationAction *> *)systemActionsForContext:(UIUserNotificationActionContext)context;

@end

NS_ASSUME_NONNULL_END
