//
//  AUTStubUserNotificationsApplication.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotificationsViewModel_Private.h>

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationsApplication : NSObject <AUTUserNotificationsApplication>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<AUTUserNotificationsAppDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL isRegisteredForRemoteNotifications;

/// An error that should be forwarded to the handler to indicate remote notification
/// registration failed.
@property (nonatomic, nullable) NSError *remoteNotificationRegistrationError;

/// A token that should be forwarded to the handler to indicate remote
/// notification registration succeeded.
@property (nonatomic, nullable) NSData *remoteNotificationRegistrationDeviceToken;

- (RACSignal<NSNumber *> *)sendSilentRemoteNotification:(NSDictionary *)remoteNotification;

@end

NS_ASSUME_NONNULL_END
