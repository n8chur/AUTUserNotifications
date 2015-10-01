//
//  AUTStubUserNotificationHandler.h
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotificationHandler.h>

NS_ASSUME_NONNULL_BEGIN

/// Provides liftable selectors that perform no action when invoked.
@interface AUTStubUserNotificationHandler : NSObject <AUTUserNotificationHandler>

@end

NS_ASSUME_NONNULL_END
