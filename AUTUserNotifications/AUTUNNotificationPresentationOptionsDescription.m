//
//  AUTUNNotificationPresentationOptionsDescription.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/2/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"

#import "AUTUNNotificationPresentationOptionsDescription.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const AUTUNNotificationPresentationOptionsDescription(UNNotificationPresentationOptions options) {
    if (options == 0) return @"None";

    NSMutableArray<NSString *> *strings = [NSMutableArray array];
    var remaining = options;

    #define TEST_FLAG(FLAG) \
        do { \
            if ((remaining & (FLAG)) != 0) { \
                remaining &= ~(FLAG); \
                [strings addObject:@(# FLAG)]; \
            } \
        } while(0)

    TEST_FLAG(UNNotificationPresentationOptionBadge);
    TEST_FLAG(UNNotificationPresentationOptionSound);
    TEST_FLAG(UNNotificationPresentationOptionAlert);

    #undef TEST_FLAG

    if (remaining != 0) {
        [strings addObject:[NSString stringWithFormat:@"%@", @(remaining)]];
    }

    return [strings componentsJoinedByString:@" | "];
}

NS_ASSUME_NONNULL_END
