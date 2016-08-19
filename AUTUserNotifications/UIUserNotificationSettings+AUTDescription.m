//
//  UIUserNotificationSettings+AUTDescription.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 8/18/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import ReactiveCocoa;

#import "UIUserNotificationSettings+AUTDescription.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const AUTUIUserNotificationTypeDescription(UIUserNotificationType);

@implementation UIUserNotificationSettings (AUTDescription)

- (NSString *)aut_description {
    NSString *typesDescription = AUTUIUserNotificationTypeDescription(self.types);

    NSString *categoriesDescription = [[[self.categories.rac_sequence
        map:^(UIUserNotificationCategory *category) {
            return category.identifier;
        }]
        array]
        componentsJoinedByString:@", "];

    return [NSString stringWithFormat:@"<%@ %p> { types: %@, categories: %@ }", self.class, self, typesDescription, categoriesDescription];
}

@end

static NSString * const AUTUIUserNotificationTypeDescription(UIUserNotificationType types) {
    NSMutableArray *strings = [NSMutableArray array];
    UIUserNotificationType remaining = types;

    #define TEST_FLAG(FLAG) \
        do { \
            if ((remaining & (FLAG)) != 0) { \
                remaining &= ~(FLAG); \
                [strings addObject:@(# FLAG)]; \
            } \
        } while(0)

    TEST_FLAG(UIUserNotificationTypeBadge);
    TEST_FLAG(UIUserNotificationTypeSound);
    TEST_FLAG(UIUserNotificationTypeAlert);

    #undef TEST_FLAG

    if (remaining != 0) {
        [strings addObject:[NSString stringWithFormat:@"%@", @(remaining)]];
    }

    return [strings componentsJoinedByString:@" | "];
}

NS_ASSUME_NONNULL_END
