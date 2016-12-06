//
//  AUTUserNotificationCenter.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

/// Describes a class that can register local and remote notifications settings
/// and schedule, cancel, and present local user notifications.
///
/// Matches methods on UNUserNotificationCenter.
@protocol AUTUserNotificationCenter <NSObject>

@property (nonatomic, nullable, weak) id <UNUserNotificationCenterDelegate> delegate;

@property (nonatomic, readonly) BOOL supportsContentExtensions;

- (void)requestAuthorizationWithOptions:(UNAuthorizationOptions)options completionHandler:(void (^)(BOOL granted, NSError * _Nullable error))completionHandler;

- (void)setNotificationCategories:(NSSet<UNNotificationCategory *> *)categories;
- (void)getNotificationCategoriesWithCompletionHandler:(void (^)(NSSet<UNNotificationCategory *> *categories))completionHandler;

- (void)getNotificationSettingsWithCompletionHandler:(void (^)(UNNotificationSettings *settings))completionHandler;

- (void)addNotificationRequest:(UNNotificationRequest *)request withCompletionHandler:(nullable void(^)(NSError * _Nullable error))completionHandler;

- (void)getPendingNotificationRequestsWithCompletionHandler:(void (^)(NSArray<UNNotificationRequest *> *requests))completionHandler;
- (void)removePendingNotificationRequestsWithIdentifiers:(NSArray<NSString *> *)identifiers;
- (void)removeAllPendingNotificationRequests;

- (void)getDeliveredNotificationsWithCompletionHandler:(void (^)(NSArray<UNNotification *> *notifications))completionHandler;
- (void)removeDeliveredNotificationsWithIdentifiers:(NSArray<NSString *> *)identifiers;
- (void)removeAllDeliveredNotifications;

@end

@interface UNUserNotificationCenter (AUTUserNotificationCenter) <AUTUserNotificationCenter>

@end

NS_ASSUME_NONNULL_END
