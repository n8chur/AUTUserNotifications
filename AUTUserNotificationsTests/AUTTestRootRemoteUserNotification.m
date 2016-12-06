//
//  AUTTestRootRemoteUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTStubUserNotificationCenter.h>

#import "AUTTestChildRemoteUserNotification.h"
#import "AUTAnotherTestChildRemoteUserNotification.h"
#import "AUTExtObjC.h"

#import "AUTTestRootRemoteUserNotification.h"

@import ObjectiveC;

NS_ASSUME_NONNULL_BEGIN

@interface UNPushNotificationTrigger (Private)

- (instancetype)_initWithContentAvailable:contentAvailable mutableContent:mutableContent;

@end

@implementation AUTTestRootRemoteUserNotification

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
    NSDictionary *aps = JSONDictionary[@"aps"];
    if (aps == nil || ![aps isKindOfClass:NSDictionary.class]) return self;

    NSString *category = aps[@"category"];
    if (category == nil || ![category isKindOfClass:NSString.class]) return self;

    if ([category isEqualToString:AUTTestChildRemoteUserNotification.systemCategoryIdentifier]) {
        return AUTTestChildRemoteUserNotification.class;
    }

    if ([category isEqualToString:AUTAnotherTestChildRemoteUserNotification.systemCategoryIdentifier]) {
        return AUTAnotherTestChildRemoteUserNotification.class;
    }

    return self;
}

+ (NSString *)systemCategoryIdentifier {
    return @"root";
}

+ (NSDictionary *)asSilentJSONDictionary {
    return @{
        @"aps": @{
            @"category": self.systemCategoryIdentifier,
            @"content-available": @1,
        }
    };
}

+ (NSDictionary *)asRemoteJSONDictionary {
    return @{
        @"aps": @{
            @"category": self.systemCategoryIdentifier,
        }
    };
}

+ (AUTStubUNNotification *)asStubNotification {
    let content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = [self asRemoteJSONDictionary];

    let request = [UNNotificationRequest
        requestWithIdentifier:self.systemCategoryIdentifier
        content:content
        trigger:[[UNPushNotificationTrigger alloc] _initWithContentAvailable:nil mutableContent:nil]];

    return [[AUTStubUNNotification alloc] initWithDate:[NSDate date] request:request];
}

+ (AUTStubUNNotificationResponse *)asStubResponseWithActionIdentifier:(NSString *)actionIdentifier {
    let notification = [self asStubNotification];
    return [[AUTStubUNNotificationResponse alloc] initWithNotification:notification actionIdentifier:actionIdentifier];
}

@end

NS_ASSUME_NONNULL_END
