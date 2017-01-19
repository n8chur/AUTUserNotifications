//
//  AUTStubUserNotificationCenter.h
//  Automatic
//
//  Created by Eric Horacek on 9/25/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import <AUTUserNotifications/AUTUserNotificationCenter.h>

@class AUTStubUNNotification;
@class AUTStubUNNotificationResponse;

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationCenter : NSObject <AUTUserNotificationCenter>

@property (nonatomic, copy) NSSet<UNNotificationCategory *> *notificationCategories;

@property (nonatomic) UNNotificationSettings *settings;

@property (nonatomic) UNAuthorizationOptions requestedAuthorizationOptions;
@property (nonatomic) BOOL authorizationGranted;
@property (nonatomic, nullable) NSError *authorizationError;

@property (nonatomic, copy) NSArray<UNNotificationRequest *> *notificationsRequests;
@property (nonatomic, copy) NSArray<AUTStubUNNotification *> *deliveredNotifications;

/// Sends the presentation options for the given notification and completes.
- (RACSignal<NSNumber *> *)presentNotification:(AUTStubUNNotification *)notification;

/// Receives the given notification response and completes.
- (RACSignal *)receiveNotification:(AUTStubUNNotificationResponse *)response;

@end

@interface AUTStubUNNotification : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDate:(NSDate *)date request:(UNNotificationRequest *)request NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, copy) NSDate *date;
@property (nonatomic, readonly) UNNotificationRequest *request;

@end

@interface AUTStubUNNotificationResponse : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNotification:(AUTStubUNNotification *)notification actionIdentifier:(NSString *)actionIdentifier NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) AUTStubUNNotification *notification;
@property (nonatomic, readonly, copy) NSString *actionIdentifier;

@end

NS_ASSUME_NONNULL_END
