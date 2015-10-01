//
//  AUTStubUserNotifier.h
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotifier.h>

@protocol AUTUserNotificationHandler;

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotifier : NSObject <AUTUserNotifier>

- (instancetype)initWithHandler:(id<AUTUserNotificationHandler>)handler;

@property (nullable, nonatomic, copy) NSMutableArray <UILocalNotification *> *scheduledLocalNotifications;

@property (readwrite, nonatomic, assign) BOOL isRegisteredForRemoteNotifications;

/// An error that should be forwarded to the handler to indicate remote notification
/// registration failed.
@property (readwrite, nonatomic, strong, nullable) NSError *remoteNotificationRegistrationError;

/// A token that should be forwarded to the handler to indicate remote
/// notification registration succeeded.
@property (readwrite, nonatomic, strong, nullable) NSData *remoteNotificationRegistrationDeviceToken;

/// Immediately sends the specified remote notification to the handler.
- (void)displayRemoteNotification:(NSDictionary *)remoteNotification;

/// Sends the specified silent remote notification to the handler.
- (void)sendSilentRemoteNotification:(NSDictionary *)remoteNotification fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))fetchCompletionHandler;

/// Performs the specified action for the given local notification.
- (void)performActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)localNotification completionHandler:(void (^)())completionHandler;

/// Performs the specified action for the given remote notification.
- (void)performActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)remoteNotification completionHandler:(void (^)())completionHandler;

@end

NS_ASSUME_NONNULL_END
