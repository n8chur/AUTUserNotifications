//
//  AUTLocalUserNotification_Private.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

#import <AUTUserNotifications/AUTLocalUserNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTLocalUserNotification ()

/// Readwrite version of a public property.
@property (readwrite, atomic, strong, nullable) UILocalNotification *systemNotification;

@end

NS_ASSUME_NONNULL_END
