//
//  AUTUserNotificationsErrors.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 8/18/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// The error domain for errors originating with AUTUserNotifications.
extern NSString * const AUTUserNotificationsErrorDomain;

/// Error codes in AUTUserNotificationsErrorDomain.
typedef NS_ENUM(NSInteger, AUTUserNotificationsErrorCodes) {
    /// A notification could not be scheduled because the user has forbidden it
    /// from being displayed.
    AUTUserNotificationsErrorUnauthorized,
};

NS_ASSUME_NONNULL_END
