//
//  AUTLocalUserNotification_Private.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTLocalUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

/// The key used to store an NSKeyedArchiver NSData representation of an
/// AUTLocalUserNotification within the userInfo of a UILocalNotification.
extern NSString * const AUTLocalUserNotificationKey;

@interface AUTLocalUserNotification ()

/// Attempts to restore a local notification from the provided request.
///
/// @return The successfully restored notification, otherwise nil if
///         unsuccessful.
+ (nullable __kindof AUTLocalUserNotification *)notificationRestoredFromRequest:(UNNotificationRequest *)request;

/// Creates a local notification request representing the receiver to be sent to
/// the system.
///
/// The returned notification request should be considered a copy. Its
/// attributes will not be updated in sync with the receiver following its
/// creation.
///
/// If a notification request could not be created, returns nil.
- (nullable UNNotificationRequest *)createNotificationRequest;

@end

NS_ASSUME_NONNULL_END
