//
//  AUTStubRemoteNotificationFetchHandler.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTStubRemoteNotificationFetchHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubRemoteNotificationFetchHandler ()

@property (readwrite, nonatomic, strong) AUTRemoteUserNotification *notification;

@end

@implementation AUTStubRemoteNotificationFetchHandler

- (instancetype)init {
    self = [super init];

    _fetchHandler = [RACSignal return:@(UIBackgroundFetchResultFailed)];

    return self;
}

- (RACSignal *)performFetchForNotification:(AUTRemoteUserNotification *)notification {
    self.notification = notification;

    return self.fetchHandler;
}

@end

NS_ASSUME_NONNULL_END
