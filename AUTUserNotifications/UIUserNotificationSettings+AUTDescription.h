//
//  UIUserNotificationSettings+AUTDescription.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 8/18/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIUserNotificationSettings (AUTDescription)

/// Returns a short debug description of the receiver.
@property (readonly, nonatomic, copy) NSString *aut_description;

@end

NS_ASSUME_NONNULL_END
