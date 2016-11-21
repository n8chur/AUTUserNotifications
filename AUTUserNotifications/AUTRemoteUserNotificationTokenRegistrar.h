//
//  AUTRemoteUserNotificationTokenRegistrar.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

NS_ASSUME_NONNULL_BEGIN

/// Describes an object that is able to register a device token with the server
/// that sends remote notifications to the application through APNS.
@protocol AUTRemoteUserNotificationTokenRegistrar <NSObject>

/// Invoked when a device token has been generated and should be registered with
/// the push notification server.
///
/// The returned signal should complete if registration was successful, or error
/// otherwise.
///
/// If the token has already been registered with the push notification server,
/// the returned signal should complete immediately.
///
/// If registration fails initially, the returned signal is encouraged to retry
/// until successful.
- (RACSignal *)registerDeviceToken:(NSData *)deviceToken;

@end

NS_ASSUME_NONNULL_END
