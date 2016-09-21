//
//  AUTTestRootRemoteUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import AUTUserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface AUTTestRootRemoteUserNotification : AUTRemoteUserNotification

/// Returns a silent representatino of a JSON dictionary that should be mapped
/// to an instance of the receiver.
+ (NSDictionary *)asSilentJSONDictionary;

/// Returns a remote representatino of a JSON dictionary that should be mapped
/// to an instance of the receiver.
+ (NSDictionary *)asRemoteJSONDictionary;

@end

NS_ASSUME_NONNULL_END
