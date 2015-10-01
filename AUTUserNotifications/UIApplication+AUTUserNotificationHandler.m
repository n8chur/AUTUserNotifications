//
//  UIApplication+AUTUserNotificationHandler.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "UIApplication+AUTUserNotificationHandler.h"

#import "AUTUserNotificationHandler.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIApplication (AUTUserNotificationHandler)

- (nullable id<AUTUserNotificationHandler>)aut_userNotificationHandler {
    if ([self.delegate conformsToProtocol:@protocol(AUTUserNotificationHandler)]) {
        return (id<AUTUserNotificationHandler>)self.delegate;
    }
    return nil;
}

@end

NS_ASSUME_NONNULL_END
