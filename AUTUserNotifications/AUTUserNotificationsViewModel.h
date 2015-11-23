//
//  AUTUserNotificationsViewModel.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UIKit;
@import ReactiveCocoa;

@class AUTUserNotification;
@class AUTLocalUserNotification;
@class AUTRemoteUserNotification;

@protocol AUTUserNotifier;
@protocol AUTUserNotificationHandler;
@protocol AUTUserNotificationActionHandler;
@protocol AUTRemoteUserNotificationFetchHandler;
@protocol AUTRemoteUserNotificationTokenRegistrar;

NS_ASSUME_NONNULL_BEGIN

/// Responsible for routing received user notifications and the actions
/// performed on them to interested consumers.
@interface AUTUserNotificationsViewModel : NSObject

/// Invokes initWithRootRemoteNotificationClass: with AUTRemoteUserNotification
/// as the rootRemoteNotificationClass.
- (instancetype)init;

/// Invokes the designated initializer with UIApplication.sharedApplication as
/// the notifier and UIApplication.sharedApplication.delegate as the handler.
///
/// Throws an exception if your UIApplication.sharedApplication.delegate does
/// not conform to AUTUserNotificationHandler.
- (instancetype)initWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass;

/// Invokes the designated initializer with AUTRemoteUserNotification as the
/// rootRemoteNotificationClass.
- (instancetype)initWithNotifier:(id<AUTUserNotifier>)notifier handler:(id<AUTUserNotificationHandler>)handler;

/// @param notifier The object that should be used to send system notifications.
///        Typically an instance of UIApplication, but can be stubbed for
///        testing purposes.
///
/// @param handler The object that should be used to handle system notifications
///        receipt and registration. Typically an object that conforms to
///        UIApplicationDelegate, but can be stubbed for testing purposes.
///
/// @param rootRemoteNotificationClass The class at the root of the hierarchy of
///        remote notification classes. Must be a subclass of
///        AUTRemoteUserNotification, and is expected to implement
///        +[MTLJSONSerializing classForParsingJSONDictionary:] to allow the
///        correct remote notification subclass to be serialized from a system
///        remote notification.
- (instancetype)initWithNotifier:(id<AUTUserNotifier>)notifier handler:(id<AUTUserNotificationHandler>)handler rootRemoteNotificationClass:(Class)rootRemoteNotificationClass NS_DESIGNATED_INITIALIZER;

/// An object that performs token registration with the server responsible for
/// sending push notifications. Invoked when executing
/// registerForRemoteNotificationsCommand.
@property (readwrite, atomic, weak, nullable) id<AUTRemoteUserNotificationTokenRegistrar> tokenRegistrar;

/// When executed, registers the provided notification settings with the system.
///
/// Should be executed with a parameter of UIUserNotificationSettings specifying
/// the settings that should be registered. If not, an exception is thrown.
///
/// Its execution signals will send a next value of UIUserNotificationSettings
/// representing the settings that were registered. This value may differ from
/// the settings that this command was executed with if the user elected to
/// limit the scope of notifications.
@property (readonly, nonatomic, strong) RACCommand *registerSettingsCommand;

/// When executed, registers for remote notifications with both the system and
/// the server responsible for sending remote notifications.
///
/// Delegates out to its token registrar to perform registration with the server
/// responsible for sending remote notifications. As such, this command is
/// disabled when tokenRegistrar is nil.
///
/// Its execution signals will not complete until settings have been registered
/// using the registerSettingsCommand.
///
/// Its execution signals will complete if registration succeeded, or error
/// otherwise. If successful, this command will become disabled. If
/// unsuccessful, this command will remain enabled.
@property (readonly, nonatomic, strong) RACCommand *registerForRemoteNotificationsCommand;

/// Sends notifications of the specified class as they are received.
///
/// The specified notification class must be kind of AUTUserNotification.
///
/// Returns a hot signal that completes when the receiver is deallocated.
- (RACSignal *)receivedNotificationsOfClass:(Class)notificationClass;

/// Registers a handler that has its action handling method invoked whenever an
/// action is performed on a notification of the specified class.
///
/// The specified notification class must be kind of AUTUserNotification (either
/// remote or local). An exception is thrown if it is not.
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
/// Returns a disposable that represents the action registration. Consumers
/// should dispose of it to unregister the action handler.
- (RACDisposable *)registerFetchHandler:(id<AUTRemoteUserNotificationFetchHandler>)fetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass;

/// Sends each AUTLocalUserNotification instance that is currently scheduled
/// upon subscription, then completes.
- (RACSignal *)scheduledLocalNotifications;

/// Sends each AUTLocalUserNotification instance that is currently scheduled and
/// of the specified class upon subscription, then completes.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal *)scheduledLocalNotificationsOfClass:(Class)notificationClass;

/// Schedules the given local notification for presentation to the user upon
/// subscription, completing when scheduling has succeeded.
///
/// If user notifications have not yet been scheduled with the system, this
/// signal will immediately error with the TODO: specify error.
- (RACSignal *)scheduleLocalNotification:(__kindof AUTLocalUserNotification *)notification;

/// Cancels all local notifications of the specified class upon subscription,
/// completing when cancellation has finished.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal *)cancelLocalNotificationsOfClass:(Class)notificationClass;

/// Cancels all local notifications of the specified class upon subscription
/// that pass the given test, completing when cancellation has finished.
///
/// The specified class must be kind of AUTLocalUserNotification (local only,
/// not remote). An exception is thrown if it is not.
- (RACSignal *)cancelLocalNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTLocalUserNotification *notification))testBlock;

@end

NS_ASSUME_NONNULL_END
