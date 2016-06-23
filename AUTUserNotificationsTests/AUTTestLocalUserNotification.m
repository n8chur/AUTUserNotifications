//
//  AUTTestLocalUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTTestLocalUserNotification.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTTestLocalUserNotification

- (nullable UILocalNotification *)createSystemNotification {
    UILocalNotification *notification = [super createSystemNotification];

    notification.fireDate = self.fireDate;

    return notification;
}

@end

@implementation AUTTestLocalUserNotificationSubclass

@end

@implementation AUTTestLocalRestorationFailureUserNotification

- (BOOL)restoreFromSystemNotification:(UILocalNotification *)notification {
    return NO;
}

@end

NS_ASSUME_NONNULL_END
