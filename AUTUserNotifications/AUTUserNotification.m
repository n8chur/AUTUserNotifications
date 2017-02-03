//
//  AUTUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import UserNotifications;
@import ReactiveObjC;

#import "AUTExtObjC.h"
#import "AUTLog.h"
#import "AUTLocalUserNotification_Private.h"
#import "AUTRemoteUserNotification_Private.h"

#import "AUTUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotification

+ (nullable __kindof AUTUserNotification *)notificationRestoredFromRequest:(UNNotificationRequest *)request rootRemoteNotificationClass:(Class)rootRemoteNotificationClass {
    AUTAssertNotNil(request, rootRemoteNotificationClass);

    __kindof AUTUserNotification * _Nullable notification;

    if ([request.trigger isKindOfClass:UNPushNotificationTrigger.class]) {
        let userInfo = request.content.userInfo;
        notification = [rootRemoteNotificationClass notificationRestoredFromDictionary:userInfo];
    }

    if (notification == nil) {
        notification = [AUTLocalUserNotification notificationRestoredFromRequest:request];
    }

    if (notification == nil) return nil;
    if (![notification restoreFromRequest:request]) return nil;

    return notification;
}

- (BOOL)restoreFromRequest:(UNNotificationRequest *)request {
    AUTAssertNotNil(request);

    self.request = request;

    return YES;
}

+ (nullable __kindof AUTUserNotification *)notificationRestoredFromResponse:(UNNotificationResponse *)response rootRemoteNotificationClass:(Class)rootRemoteNotificationClass completionHandler:(nullable void(^)())completionHandler {
    AUTAssertNotNil(response, rootRemoteNotificationClass);

    let notification = [self notificationRestoredFromRequest:response.notification.request rootRemoteNotificationClass:rootRemoteNotificationClass];
    if (notification == nil) return nil;

    notification.responseCompletionHandler = completionHandler;

    if (![notification restoreFromResponse:response]) return nil;

    return notification;
}

- (BOOL)restoreFromResponse:(UNNotificationResponse *)response {
    AUTAssertNotNil(response);

    self.response = response;

    return YES;
}

+ (nullable UNNotificationCategory *)systemCategory {
    let identifier = [self systemCategoryIdentifier];
    let actions = [self systemCategoryActions];
    let options = [self systemCategoryOptions];
    let intentIdentifiers = [self systemCategoryIntentIdentifiers];

    return [UNNotificationCategory
        categoryWithIdentifier:identifier
        actions:actions
        intentIdentifiers:intentIdentifiers
        options:options];
}

+ (NSString *)systemCategoryIdentifier {
    return NSStringFromClass(self);
}

+ (UNNotificationCategoryOptions)systemCategoryOptions {
    return UNNotificationCategoryOptionNone;
}

+ (NSArray<UNNotificationAction *> *)systemCategoryActions {
    return @[];
}

+ (NSArray<NSString *> *)systemCategoryIntentIdentifiers {
    return @[];
}

#pragma mark - MTLModel

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    // Any state related to restoration should not be persisted.
    BOOL isNotStored = (
        [propertyKey isEqualToString:@keypath(AUTUserNotification.new, responseCompletionHandler)] ||
        [propertyKey isEqualToString:@keypath(AUTUserNotification.new, request)] ||
        [propertyKey isEqualToString:@keypath(AUTUserNotification.new, response)]
    );

    if (isNotStored) return MTLPropertyStorageNone;

    return [super storageBehaviorForPropertyWithKey:propertyKey];
}

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    return [super.encodingBehaviorsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary:@{
        // Any state related to restoration should not be persisted.
        @keypath(AUTUserNotification.new, responseCompletionHandler): @(MTLModelEncodingBehaviorExcluded),
        @keypath(AUTUserNotification.new, request): @(MTLModelEncodingBehaviorExcluded),
        @keypath(AUTUserNotification.new, response): @(MTLModelEncodingBehaviorExcluded),
    }];
}

@end

NS_ASSUME_NONNULL_END
