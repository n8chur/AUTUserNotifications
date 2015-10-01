//
//  UIUserNotificationSettings+AUTSynthesizedSettings.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIUserNotificationSettings (AUTSynthesizedSettings)

/// Creates and returns a settings object that can be used to register the given
/// notification types.
///
/// Synthesizes the set of categories by enumerating the subclasses of
/// AUTUserNotification and querying their systemCategory.
+ (instancetype)aut_synthesizedSettingsForTypes:(UIUserNotificationType)types;

@end

NS_ASSUME_NONNULL_END
