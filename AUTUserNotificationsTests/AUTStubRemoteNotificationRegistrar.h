//
//  AUTStubRemoteNotificationRegistrar.h
//  Automatic
//
//  Created by Eric Horacek on 9/27/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubRemoteNotificationRegistrar : NSObject <AUTRemoteUserNotificationTokenRegistrar>

/// The device token that the receiver was asked to register.
@property (readonly, nonatomic, strong) NSData *registeredDeviceToken;

/// A signal that represents registering the token when the registration method
/// is invoked.
@property (readwrite, nonatomic, strong) RACSignal *registerToken;

@end

NS_ASSUME_NONNULL_END
