//
//  UNUserNotificationCenter+AUTSynthesizedCategories.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface UNUserNotificationCenter (AUTSynthesizedCategories)

/// Sets categories synthesized by enumerating the subclasses of
/// AUTUserNotification and querying their systemCategory.
- (void)aut_setSynthesizedCategories;

@end

NS_ASSUME_NONNULL_END
