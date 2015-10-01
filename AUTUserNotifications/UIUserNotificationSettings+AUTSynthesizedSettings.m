//
//  UIUserNotificationSettings+AUTSynthesizedSettings.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveCocoa;

#import "AUTSubclassesOf.h"

#import "AUTUserNotification.h"
#import "UIUserNotificationSettings+AUTSynthesizedSettings.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIUserNotificationSettings (AUTSynthesizedSettings)

+ (instancetype)aut_synthesizedSettingsForTypes:(UIUserNotificationType)types {
    return [self settingsForTypes:types categories:self.aut_synthesizedCategories];
}

+ (NSSet <UIUserNotificationCategory *> *)aut_synthesizedCategories {
    NSArray *categories = [[[[aut_subclassesOf(AUTUserNotification.class)
        rac_sequence]
        map:^(Class notificationClass) {
            return [notificationClass systemCategory];
        }]
        filter:^ BOOL (UIUserNotificationCategory *category) {
            return category != nil;
        }]
        array];

    // Filter out duplicate categories, if there were any.
    return [NSSet setWithArray:categories];
}

@end

NS_ASSUME_NONNULL_END
