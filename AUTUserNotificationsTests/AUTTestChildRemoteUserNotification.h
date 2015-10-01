//
//  AUTTestChildRemoteUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTTestRootRemoteUserNotification.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTTestChildRemoteUserNotification : AUTTestRootRemoteUserNotification

/// Returns a JSON dictionary that should be mapped to an instance of the
/// receiver.
+ (NSDictionary *)asJSONDictionary;

@end

NS_ASSUME_NONNULL_END
