//
//  UIApplication+AUTUserNotifier.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

#import <AUTUserNotifications/AUTUserNotifier.h>

NS_ASSUME_NONNULL_BEGIN

/// Conforms UIApplication to AUTUserNotifier
@interface UIApplication (AUTUserNotifier) <AUTUserNotifier>

@end

NS_ASSUME_NONNULL_END
