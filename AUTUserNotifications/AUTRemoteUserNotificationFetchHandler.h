//
//  AUTRemoteUserNotificationFetchHandler.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveCocoa;

@class AUTRemoteUserNotification;

NS_ASSUME_NONNULL_BEGIN

/// Describes an object that is able to perform a fetch in response to a remote
/// user notification.
@protocol AUTRemoteUserNotificationFetchHandler <NSObject>

/// Invoked when a fetch should be performed for the specified remote user
/// notification.
///
/// The returned signal not error and should send a UIBackgroundFetchResult
/// indicating the result of the fetch and then complete. This is typically a
/// trigger for the system to suspend the application. If it does not conforms
/// to this behavior, an exception will be thrown.
- (RACSignal *)performFetchForNotification:(AUTRemoteUserNotification *)notification;

@end

NS_ASSUME_NONNULL_END
