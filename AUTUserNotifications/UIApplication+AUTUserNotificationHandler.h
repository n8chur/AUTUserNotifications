//
//  UIApplication+AUTUserNotificationHandler.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

@protocol AUTUserNotificationHandler;

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (AUTUserNotificationHandler)

/// Returns the delegate of the receiver if it conforms to
/// AUTUserNotificationHandler, otherwise nil.
- (nullable id<AUTUserNotificationHandler>)aut_userNotificationHandler;

@end

NS_ASSUME_NONNULL_END
