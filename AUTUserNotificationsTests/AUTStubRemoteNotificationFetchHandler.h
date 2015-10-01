//
//  AUTStubRemoteNotificationFetchHandler.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubRemoteNotificationFetchHandler : NSObject <AUTRemoteUserNotificationFetchHandler>

/// The handler for the fetch. Sends UIBackgroundFetchResultFailed by default.
@property (readwrite, nonatomic, strong) RACSignal *fetchHandler;

/// The notification that a fetch was performed for.
@property (readonly, nonatomic, strong) AUTRemoteUserNotification *notification;

@end

NS_ASSUME_NONNULL_END
