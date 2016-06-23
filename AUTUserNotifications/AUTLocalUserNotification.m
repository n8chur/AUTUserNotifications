//
//  AUTLocalUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Mantle;
@import ReactiveCocoa;

#import "AUTLog.h"

#import "AUTUserNotification_Private.h"
#import "AUTLocalUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const AUTLocalUserNotificationKey = @"AUTLocalUserNotification";

@implementation AUTLocalUserNotification

@dynamic badgeCount, sound, category, localizedTitle, localizedBody, localizedAction, launchImageFilename;

#pragma mark - Lifecycle

+ (nullable instancetype)notificationRestoredFromSystemNotification:(UILocalNotification *)systemNotification withActionIdentifier:(nullable NSString *)actionIdentifier systemActionCompletionHandler:(nullable void (^)())systemActionCompletionHandler {
    NSParameterAssert(systemNotification != nil);

    if (systemNotification.userInfo == nil) {
        AUTLogLocalUserNotificationInfo(@"Notification has no userInfo, skipping unarchiving of AUTLocalUserNotification: %@", systemNotification);
        return nil;
    }

    NSData *encodedSelf = systemNotification.userInfo[AUTLocalUserNotificationKey];
    if (encodedSelf == nil) {
        AUTLogLocalUserNotificationInfo(@"Notification userInfo has no %@ key, skipping unarchiving of AUTLocalUserNotification: %@", AUTLocalUserNotificationKey, systemNotification);
        return nil;
    }

    // Unarchive self from the local notification.
    AUTLocalUserNotification *notification;
    @try {
        notification = [NSKeyedUnarchiver unarchiveObjectWithData:encodedSelf];
    } @catch (NSException* exception) {
        AUTLogLocalUserNotificationError(@"Caught exception while attempting to unarchive an AUTLocalUserNotification encoded within system notification: %@, exception: %@", systemNotification, exception);
        return nil;
    }

    if (notification == nil || ![notification isKindOfClass:AUTLocalUserNotification.class]) {
        AUTLogLocalUserNotificationError(@"Failed to unarchive an AUTLocalUserNotification encoded within system notification: %@", systemNotification);
        return nil;
    }

    notification.systemNotification = systemNotification;
    notification.actionIdentifier = actionIdentifier;
    notification.systemActionCompletionHandler = systemActionCompletionHandler;

    if (![notification restoreFromSystemNotification:systemNotification]) return nil;

    return notification;
}

#pragma mark - MTLModel

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    if ([propertyKey isEqualToString:@keypath(AUTLocalUserNotification.new, systemNotification)]) {
        return MTLPropertyStorageTransitory;
    }

    return [super storageBehaviorForPropertyWithKey:propertyKey];
}

+ (NSDictionary *)encodingBehaviorsByPropertyKey {
    return [[super encodingBehaviorsByPropertyKey] mtl_dictionaryByAddingEntriesFromDictionary:@{
        @keypath(AUTLocalUserNotification.new, systemNotification): @(MTLModelEncodingBehaviorExcluded),
    }];
}

#pragma mark - AUTLocalUserNotification

- (nullable UILocalNotification *)createSystemNotification {
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    // TODO: Restore some information from self.systemNotification, if needed?

    // Store self within the notification's user info, for later restoration
    // upon a subsequent launch.
    notification.userInfo = @{
        AUTLocalUserNotificationKey: [NSKeyedArchiver archivedDataWithRootObject:self],
    };

    notification.category = [self.class systemCategoryIdentifier];

    return notification;
}

- (BOOL)restoreFromSystemNotification:(UILocalNotification *)notification {
    return YES;
}

#pragma mark - AUTUserNotificationAlertDisplayable

- (nullable NSString *)localizedBody {
    return self.systemNotification.alertBody;
}

- (nullable NSString *)localizedTitle {
    return self.systemNotification.alertTitle;
}

- (nullable NSString *)localizedAction {
    return self.systemNotification.alertAction;
}

- (nullable NSString *)sound {
    return self.systemNotification.soundName;
}

- (nullable NSString *)launchImageFilename {
    return self.systemNotification.alertLaunchImage;
}

- (nullable NSString *)category {
    return self.systemNotification.category;
}

- (nullable NSNumber *)badgeCount {
    return @(self.systemNotification.applicationIconBadgeNumber);
}

@end

NS_ASSUME_NONNULL_END
