//
//  UNUserNotificationCenter+AUTSynthesizedCategories.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTSubclassesOf.h"
#import "AUTUserNotification_Private.h"

#import "UNUserNotificationCenter+AUTSynthesizedCategories.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UNUserNotificationCenter (AUTSynthesizedCategories)

- (void)aut_setSynthesizedCategories {
    [self setNotificationCategories:self.aut_synthesizedCategories];
}

- (NSSet<UNNotificationCategory *> *)aut_synthesizedCategories {
    NSArray<UNNotificationCategory *> *categories = [[[aut_subclassesOf(AUTUserNotification.class).rac_sequence
        map:^(Class notificationClass) {
            return [notificationClass systemCategory];
        }]
        filter:^ BOOL (UNNotificationCategory *category) {
            return category != nil;
        }]
        array];

    return [NSSet setWithArray:categories];
}

@end

NS_ASSUME_NONNULL_END
