//
//  AUTUserNotificationsViewModel.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;
@import ReactiveObjC;

@class AUTUserNotification;
@class AUTLocalUserNotification;
@class AUTRemoteUserNotification;

@protocol AUTUserNotificationCenter;
@protocol AUTUserNotificationActionHandler;
@protocol AUTRemoteUserNotificationFetchHandler;
@protocol AUTRemoteUserNotificationTokenRegistrar;

NS_ASSUME_NONNULL_BEGIN

/// Responsible for routing received user notifications and the actions
/// performed on them to interested consumers.
@interface AUTUserNotificationsViewModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Invokes the designated initializer with
/// UNUserNotificationCenter.currentNotificationCenter as the center.
- (instancetype)initWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions;

/// When executed with an UNAuthorizationOptions, requests authorization to
/// present notifications with the provided options.
///
/// Its execution signals send the granted settings if successful, and error
/// otherwise.
@property (readonly, nonatomic) RACCommand<NSNumber *, UNNotificationSettings *> *requestAuthorization;

/// Sends the current user notification settings and completes.
@property (readonly, nonatomic) RACSignal<UNNotificationSettings *> *settings;

/// When executed with a token registrar, registers for remote notifications
/// with both the system and the server responsible for sending remote
/// notifications.
///
/// Delegates out to the provided token registrar to perform registration with
/// the server responsible for sending remote notifications.
///
/// Its execution signals will complete if registration succeeded, or error
/// otherwise. If successful, this command will become disabled. If
/// unsuccessful, this command will remain enabled.
@property (readonly, nonatomic) RACCommand<id<AUTRemoteUserNotificationTokenRegistrar>, id> *registerForRemoteNotifications;

/// A hot signal that sends non-silent notifications that are subclasses of
/// AUTUserNotification as they are presented.
///
/// Values are sent on a background scheduler prior to the presentation options
/// being delivered to the system.
///
/// A hot signal that completes when the receiver is deallocated.
@property (readonly, nonatomic) RACSignal<__kindof AUTUserNotification *> *presentedNotifications;

/// Sends non-silent notifications of the specified class as they are presented.
///
/// The specified notification class must be kind of AUTUserNotification.
///
/// Values are sent on a background scheduler prior to the presentation options
/// being delivered to the system.
///
/// Returns a hot signal that completes when the receiver is deallocated.
- (RACSignal<__kindof AUTUserNotification *> *)presentedNotificationsOfClass:(Class)notificationClass;

/// Registers a handler that has its action handling method invoked whenever an
/// action is performed on a notification of the specified class.
///
/// The specified notification class must be kind of AUTUserNotification (either
/// remote or local). An exception is thrown if it is not.
///
/// The actionHandler is not retained.
///
/// Returns a disposable that represents the action registration. Consumers
/// should dispose of it to unregister the action handler.
- (RACDisposable *)registerActionHandler:(id<AUTUserNotificationActionHandler>)actionHandler forNotificationsOfClass:(Class)notificationClass;

/// Registers an handler that has its fetch handling method invoked whenever a
/// fetch is performed for a remote notification of the specified class.
///
/// The specified notification class must be kind of AUTRemoteUserNotification
/// (remote only, not local). An exception is thrown if it is not.
///
/// The fetchHandler is not retained.
///
/// Returns a disposable that represents the action registration. Consumers
/// should dispose of it to unregister the action handler.
- (RACDisposable *)registerFetchHandler:(id<AUTRemoteUserNotificationFetchHandler>)fetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass;

/// Should return an NSNumber-wrapped UNNotificationPresentationOptions
/// indicating the presentation override that should occur for the given
/// notification, or else nil of no override should occur.
typedef NSNumber * _Nullable (^AUTUserNotificationPresentationOverride)(__kindof AUTUserNotification *notification);

/// Adds an override that is invoked to override the defaultPresentationOptions
/// specified at initialization with the presentation options returned from the
/// given override for a specific notification.
///
/// Overrides evaluated in the order that they are added. The first override to
/// return a non-nil presentation option is used. If no overrides return a
/// value, the default presentation options are used.
///
/// @return A disposable that should be used to remove the override.
- (RACDisposable *)addPresentationOverride:(AUTUserNotificationPresentationOverride)presentationOverride;

@end

@interface AUTUserNotificationsViewModel (Scheduling)

/// Sends each local notification that is currently scheduled upon subscription,
/// then completes.
- (RACSignal<__kindof AUTLocalUserNotification *> *)scheduledLocalNotifications;

/// Sends each local notification that is currently scheduled and of the
/// specified class upon subscription, then completes.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal<__kindof AUTLocalUserNotification *> *)scheduledLocalNotificationsOfClass:(Class)notificationClass;

/// Schedules the given local notification for presentation to the user upon
/// subscription, completing if scheduling was succeesful, or else erroring if
/// scheduling was unsuccessful.
- (RACSignal *)scheduleLocalNotification:(__kindof AUTLocalUserNotification *)notification;

/// Unschedules all local notifications of the specified class upon
/// subscription, completing when successful.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal *)unscheduleLocalNotificationsOfClass:(Class)notificationClass;

/// Unschedules all local notifications of the specified class that pass the
/// given test upon subscription, completing when successful.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal *)unscheduleLocalNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTLocalUserNotification *notification))test;

@end

@interface AUTUserNotificationsViewModel (Delivery)

/// Sends each delivered notification upon subscription, then completes.
- (RACSignal<__kindof AUTUserNotification *> *)deliveredNotifications;

/// Sends each delivered notification of the specified class upon subscription,
/// then completes.
///
/// The specified class must be kind of AUTUserNotification. An exception is
/// thrown if it is not.
- (RACSignal<__kindof AUTUserNotification *> *)deliveredNotificationsOfClass:(Class)notificationClass;

/// Cancels all delivered notifications of the specified class upon
/// subscription, completing when removal has finished.
///
/// The specified class must be kind of AUTUserNotification. An exception is
/// thrown if it is not.
- (RACSignal *)removeDeliveredNotificationsOfClass:(Class)notificationClass;

/// Cancels all delivered notifications of the specified class that pass the
/// give test upon subscription, completing when removal has finished.
///
/// The specified class must be kind of AUTUserNotification. An exception is
/// thrown if it is not.
- (RACSignal *)removeDeliveredNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTUserNotification *notification))testBlock;

@end

NS_ASSUME_NONNULL_END
