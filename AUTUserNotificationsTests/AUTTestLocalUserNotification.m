//
//  AUTTestLocalUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"

#import "AUTTestLocalUserNotification.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTTestLocalUserNotification

- (instancetype)init {
    self = [super init];
    _triggerTimeInterval = 0.1;
    return self;
}

- (nullable UNMutableNotificationContent *)createNotificationContent {
    let content = [super createNotificationContent];
    if (content == nil) return nil;

    content.body = @"AUTTestLocalUserNotification";

    return content;
}

- (nullable UNNotificationTrigger *)createNotificationTrigger {
    return [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:self.triggerTimeInterval repeats:NO];
}

@end

@implementation AUTTestLocalUserNotificationSubclass

@end

@implementation AUTTestLocalRestorationFailureUserNotification

- (BOOL)restoreFromRequest:(UNNotificationRequest *)request {
    if (![super restoreFromRequest:request]) return NO;

    return NO;
}

@end

NS_ASSUME_NONNULL_END
