//
//  AUTStubUserNotificationActionHandler.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"

#import "AUTStubUserNotificationActionHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationActionHandler ()

@property (readwrite, nonatomic, strong) AUTUserNotification *notification;

@end

@implementation AUTStubUserNotificationActionHandler

- (instancetype)init {
    self = [super init];

    _actionHandler = [RACSignal empty];

    return self;
}

- (RACSignal *)performActionForNotification:(AUTUserNotification *)notification {
    self.notification = notification;

    return AUTNotNil(self.actionHandler ?: [RACSignal empty]);
}

@end

NS_ASSUME_NONNULL_END
