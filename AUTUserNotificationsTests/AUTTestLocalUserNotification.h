//
//  AUTTestLocalUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface AUTTestLocalUserNotification : AUTLocalUserNotification

/// The time interval for the notification that is created by the receiver.
@property (nonatomic) NSTimeInterval triggerTimeInterval;

@end

@interface AUTTestLocalUserNotificationSubclass : AUTTestLocalUserNotification

@end

@interface AUTTestLocalRestorationFailureUserNotification : AUTLocalUserNotification

@end

NS_ASSUME_NONNULL_END
