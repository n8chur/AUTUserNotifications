//
//  AUTStubRemoteNotificationRegistrar.m
//  Automatic
//
//  Created by Eric Horacek on 9/27/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTStubRemoteNotificationRegistrar.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubRemoteNotificationRegistrar ()

@property (readwrite, nonatomic, strong) NSData *registeredDeviceToken;

@end

@implementation AUTStubRemoteNotificationRegistrar

- (instancetype)init {
    self = [super init];

    _registerToken = [RACSignal empty];

    return self;
}

- (RACSignal *)registerDeviceToken:(NSData *)deviceToken {
    self.registeredDeviceToken = deviceToken;

    return self.registerToken;
}

@end

NS_ASSUME_NONNULL_END
