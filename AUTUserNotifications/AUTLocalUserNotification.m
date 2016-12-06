//
//  AUTLocalUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"
#import "AUTLog.h"
#import "AUTUserNotification_Private.h"

#import "AUTLocalUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const AUTLocalUserNotificationKey = @"AUTLocalUserNotification";

@implementation AUTLocalUserNotification

#pragma mark - AUTLocalUserNotification

#pragma mark Public

- (nullable UNMutableNotificationContent *)createNotificationContent {
    let content = [[UNMutableNotificationContent alloc] init];

    let archive = [NSKeyedArchiver archivedDataWithRootObject:self];
    content.userInfo = @{ AUTLocalUserNotificationKey: archive };

    content.categoryIdentifier = [self.class systemCategoryIdentifier];

    return content;
}

- (nullable UNNotificationTrigger *)createNotificationTrigger {
    // 0.0s causes an exception to be thrown.
    return [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.01 repeats:NO];
}

- (nullable NSString *)createNotificationIdentifier {
    return [NSUUID UUID].UUIDString;
}

#pragma mark Private

+ (nullable __kindof AUTLocalUserNotification *)notificationRestoredFromRequest:(UNNotificationRequest *)request {
    AUTAssertNotNil(request);

    let userInfo = request.content.userInfo;

    if (userInfo == nil) {
        AUTLogUserNotificationInfo(@"Notification has no userInfo, skipping unarchiving of AUTLocalUserNotification from request %@", request);
        return nil;
    }

    let encodedSelf = (NSData *)userInfo[AUTLocalUserNotificationKey];
    if (encodedSelf == nil || ![encodedSelf isKindOfClass:NSData.class]) {
        AUTLogUserNotificationInfo(@"Notification userInfo has no data for %@, skipping unarchiving of AUTLocalUserNotification from request %@ with userInfo %@", AUTLocalUserNotificationKey, request, userInfo);
        return nil;
    }

    // Unarchive self from the local notification.
    AUTLocalUserNotification *notification;
    @try {
        notification = [NSKeyedUnarchiver unarchiveObjectWithData:encodedSelf];
    } @catch (NSException* exception) {
        AUTLogUserNotificationError(@"Caught exception while attempting to unarchive an AUTLocalUserNotification encoded from request %@ userInfo %@, exception: %@", request, userInfo, exception);
        return nil;
    }

    if (notification == nil || ![notification isKindOfClass:AUTLocalUserNotification.class]) {
        AUTLogUserNotificationError(@"Failed to unarchive an AUTLocalUserNotification from request %@ userInfo %@, instead found %@", request, userInfo, notification);
        return nil;
    }

    notification.request = request;

    return notification;
}

- (nullable UNNotificationRequest *)createNotificationRequest {

    let identifier = [self createNotificationIdentifier];
    if (identifier == nil) return nil;

    let trigger = [self createNotificationTrigger];
    if (trigger == nil) return nil;

    let content = [self createNotificationContent];
    if (content == nil) return nil;

    return [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
}

@end

NS_ASSUME_NONNULL_END
