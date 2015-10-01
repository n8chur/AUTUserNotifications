//
//  AUTStubUserNotificationActionHandler.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationActionHandler : NSObject <AUTUserNotificationActionHandler>

/// The handler for the fetch. Completes immediately by default.
@property (readwrite, nonatomic, strong) RACSignal *actionHandler;

/// The notification that a fetch was performed for.
@property (readonly, nonatomic, strong) AUTUserNotification *notification;

@end

NS_ASSUME_NONNULL_END
