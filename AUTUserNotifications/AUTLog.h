//
//  AUTLog.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTLogKit;

/// A context for logging events related to user notifications.
AUTLOGKIT_CONTEXT_DECLARE(AUTLogContextUserNotifications);

#define AUTLogUserNotificationError(frmt, ...) AUTLogError(AUTLogContextUserNotifications, frmt, ##__VA_ARGS__)
#define AUTLogUserNotificationInfo(frmt, ...)  AUTLogInfo(AUTLogContextUserNotifications, frmt, ##__VA_ARGS__)
