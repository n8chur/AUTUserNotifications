//
//  AUTLog.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTLogKit;

/// A context for logging events related to remote user notifications.
extern AUTLogContext AUTLogContextRemoteUserNotifications;

#define AUTLogRemoteUserNotificationError(frmt, ...) AUTLogError(AUTLogContextRemoteUserNotifications, frmt, ##__VA_ARGS__)
#define AUTLogRemoteUserNotificationInfo(frmt, ...)  AUTLogInfo(AUTLogContextRemoteUserNotifications, frmt, ##__VA_ARGS__)

/// A context for logging events related to local user notifications.
extern AUTLogContext AUTLogContextLocalUserNotifications;

#define AUTLogLocalUserNotificationError(frmt, ...) AUTLogError(AUTLogContextLocalUserNotifications, frmt, ##__VA_ARGS__)
#define AUTLogLocalUserNotificationInfo(frmt, ...)  AUTLogInfo(AUTLogContextLocalUserNotifications, frmt, ##__VA_ARGS__)

/// A context for logging events related to registration of user notification
/// display settings and token registration.
extern AUTLogContext AUTLogContextUserNotificationRegistration;

#define AUTLogUserNotificationRegistrationError(frmt, ...) AUTLogError(AUTLogContextUserNotificationRegistration, frmt, ##__VA_ARGS__)
#define AUTLogUserNotificationRegistrationInfo(frmt, ...)  AUTLogInfo(AUTLogContextUserNotificationRegistration, frmt, ##__VA_ARGS__)
