//
//  AUTTestRootRemoteUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

@class AUTStubUNNotification;
@class AUTStubUNNotificationResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AUTTestRootRemoteUserNotification : AUTRemoteUserNotification

/// Returns a silent representation of a JSON dictionary that should be mapped
/// to an instance of the receiver.
+ (NSDictionary *)asSilentJSONDictionary;

/// Returns a UserNotifications representation of the receiver as a notification.
+ (AUTStubUNNotification *)asStubNotification;

/// Returns a UserNotifications representation of the receiver as a respose.
+ (AUTStubUNNotificationResponse *)asStubResponseWithActionIdentifier:(NSString *)actionIdentifier;

@end

NS_ASSUME_NONNULL_END
