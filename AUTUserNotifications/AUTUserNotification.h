//
//  AUTUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;
@import Mantle;

NS_ASSUME_NONNULL_BEGIN

/// An abstract base class for remote or local notifications.
///
/// Inherits from MTLModel so that a notification can be archived for storage
/// in a system local notification between launches of the application, and so
/// that a remote notification's properties can be mapped from the JSON payload
/// of a remote notification.
@interface AUTUserNotification : MTLModel

/// The response that the receiver restored from, or else nil if the
/// notification has yet to be received.
///
/// This property is not considered for equality checks nor included if the
/// receiver is archived.
@property (readonly, nonatomic, nullable) UNNotificationResponse *response;

/// Restores attributes on the receiver from a notification response.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the notification that is restored from a notification response.
///
/// @return NO if the receiver could not be restored from the specified
///         response, otherwise YES.
- (BOOL)restoreFromResponse:(UNNotificationResponse *)response;

/// The request that the receiver restored from, or else nil if the receiver
/// was not restored from a request.
///
/// This property is not considered for equality checks nor included if the
/// receiver is archived.
@property (readonly, nonatomic, nullable) UNNotificationRequest *request;

/// Restores attributes on the receiver from a notification request.
///
/// Subclasses are encouraged to override this method if they desire to
/// customize the notification that is restored from a notification request.
///
/// @return NO if the receiver could not be restored from the specified
///         request, otherwise YES.
- (BOOL)restoreFromRequest:(UNNotificationRequest *)request;

/// The category identifier for an instance of the receiver.
///
/// Defaults to a string representation of the class, using NSStringFromClass().
///
/// Subclasses may override this method to provide a custom category identifier.
/// This is required in the case of remote notifications.
///
/// @see -[UNNotificationCategory identifier];
@property (readonly, nonatomic, copy, class) NSString *systemCategoryIdentifier;

/// The category options for an instance of the receiver.
///
/// The default implementation of this method returns .none.
///
/// Subclasses may override this method to provide a custom category identifier.
/// This is required in the case of remote notifications.
///
/// @see -[UNNotificationCategory options];
@property (readonly, nonatomic, class) UNNotificationCategoryOptions systemCategoryOptions;

/// The actions that are available on an instance of the receiver.
///
/// Subclasses should override this method to provide the actions available on
/// a notification of the receiver's class.
///
/// The default implementation of this method returns an empty array.
///
/// @see -[UNNotificationCategory actions];
@property (readonly, nonatomic, copy, class) NSArray<UNNotificationAction *> *systemCategoryActions;

/// The intents that are available on an instance of the receiver.
///
/// Subclasses should override this method to provide the actions available on
/// a notification of the receiver's class.
///
/// The default implementation of this method returns an empty array.
///
/// @see -[UNNotificationCategory intentIdentifiers];
@property (readonly, nonatomic, copy, class) NSArray<NSString *> *systemCategoryIntentIdentifiers;

/// Attempts to restore a notification from the provided request.
///
/// Should be invoked to build a user notification in cases where a
/// UNNotificationRequest is delivered outside of the context of a
/// UNUserNotificationCenter, e.g. in a notification content or notification
/// service extension.
///
/// @return The successfully restored notification, otherwise nil if
///         unsuccessful.
+ (nullable __kindof AUTUserNotification *)notificationRestoredFromRequest:(UNNotificationRequest *)request rootRemoteNotificationClass:(Class)rootRemoteNotificationClass;

@end

NS_ASSUME_NONNULL_END
