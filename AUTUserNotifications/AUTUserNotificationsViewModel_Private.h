//
//  AUTUserNotificationsViewModel_Private.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotificationsViewModel.h>

@protocol AUTUserNotificationsAppDelegate;

NS_ASSUME_NONNULL_BEGIN

/// Describes an object that is able to issue a device token.
///
/// Matches methods on UIApplication.
@protocol AUTUserNotificationsApplication <NSObject>

- (void)registerForRemoteNotifications;

@end

@interface UIApplication () <AUTUserNotificationsApplication>

@end

@interface AUTUserNotificationsViewModel ()

/// @param center The object that should be used to send system notifications.
///        Typically an instance of UNUserNotificationCenter, but can be stubbed
///        for testing purposes.
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
- (instancetype)initWithCenter:(id<AUTUserNotificationCenter>)center application:(id<AUTUserNotificationsApplication>)application appDelegate:(id<AUTUserNotificationsAppDelegate>)appDelegate rootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) NSObject<AUTUserNotificationCenter> *center;
@property (readonly, nonatomic) Class rootRemoteNotificationClass;

@end

NS_ASSUME_NONNULL_END
