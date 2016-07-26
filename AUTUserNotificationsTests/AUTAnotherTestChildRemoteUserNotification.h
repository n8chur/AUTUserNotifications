//
//  AUTAnotherTestChildRemoteUserNotification.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 7/25/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTTestRootRemoteUserNotification.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTAnotherTestChildRemoteUserNotification : AUTTestRootRemoteUserNotification

/// Returns a JSON dictionary that should be mapped to an instance of the
/// receiver.
+ (NSDictionary *)asJSONDictionary;

@end

NS_ASSUME_NONNULL_END
