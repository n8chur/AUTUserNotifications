//
//  AUTUserNotificationActionHandler.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

@class AUTUserNotification;

NS_ASSUME_NONNULL_BEGIN

/// Describes an object that is able to handle an action for a user
/// notification.
@protocol AUTUserNotificationActionHandler <NSObject>

/// Invoked when an action should be performed for the specified user
/// notification.
///
/// The action that should be performed is identified by the actionIdentifier
/// property on the passed AUTUserNotification instance.
///
/// The returned signal should not error and should complete when the action has
/// been performed. This is typically a trigger for the system to suspend the
/// application.
- (RACSignal *)performActionForNotification:(AUTUserNotification *)notification;

@end

NS_ASSUME_NONNULL_END
