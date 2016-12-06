//
//  AUTUNAuthorizationOptionsDescription.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 8/18/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"

#import "AUTUNAuthorizationOptionsDescription.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const AUTUNAuthorizationOptionsDescription(UNAuthorizationOptions options) {
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

    TEST_FLAG(UNAuthorizationOptionBadge);
    TEST_FLAG(UNAuthorizationOptionSound);
    TEST_FLAG(UNAuthorizationOptionAlert);
    TEST_FLAG(UNAuthorizationOptionCarPlay);

    #undef TEST_FLAG

    if (remaining != 0) {
        [strings addObject:[NSString stringWithFormat:@"%@", @(remaining)]];
    }

    return [strings componentsJoinedByString:@" | "];
}

NS_ASSUME_NONNULL_END
