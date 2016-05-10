//
//  AUTUserNotificationsWeakBox.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 5/9/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTUserNotificationsWeakBox.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotificationsWeakBox

- (instancetype)initWithValue:(nullable __weak id)value {
    self = [super init];

    _value = value;

    return self;
}

+ (instancetype)box:(nullable __weak id)value {
    return [[self alloc] initWithValue:value];
}

@end

NS_ASSUME_NONNULL_END
