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

/// The fire date that the notification that is created by the receiver.
///
/// Default value of nil, which means the notification is scheduled for
/// immediate display.
@property (readwrite, nonatomic, copy, nullable) NSDate *fireDate;

@end

@interface AUTTestLocalUserNotificationSubclass : AUTTestLocalUserNotification

@end

@interface AUTTestLocalRestorationFailureUserNotification : AUTLocalUserNotification

@end

NS_ASSUME_NONNULL_END
