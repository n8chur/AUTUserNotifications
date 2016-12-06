//
//  AUTRemoteUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTExtObjC.h"
#import "AUTLog.h"

#import "AUTRemoteUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTRemoteUserNotification

#pragma mark - AUTRemoteUserNotification

#pragma mark Private

+ (nullable __kindof AUTRemoteUserNotification *)notificationRestoredFromDictionary:(NSDictionary *)dictionary {
    AUTAssertNotNil(dictionary);

    AUTLogUserNotificationInfo(@"Attempting to parse AUTRemoteUserNotification from dictionary %@", dictionary);

    NSError *error;
    __kindof AUTRemoteUserNotification *notification = [MTLJSONAdapter modelOfClass:self fromJSONDictionary:dictionary error:&error];

    if (notification == nil) {
        AUTLogUserNotificationError(@"Unable to generate AUTRemoteUserNotification from dictionary: %@, error: %@", dictionary, error);
    }

    return notification;
}

#pragma mark - AUTRemoteUserNotification <MTLJSONSerializing>

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @keypath(AUTRemoteUserNotification.new, silent): @"aps.content-available",
    };
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
    return self;
}

+ (nullable NSString *)categoryForJSONDictionary:(NSDictionary *)JSONDictionary {
    NSDictionary *aps = JSONDictionary[@"aps"];
    if (aps == nil || ![aps isKindOfClass:NSDictionary.class]) return nil;
    
    NSString *category = aps[@"category"];
    if (category == nil || ![category isKindOfClass:NSString.class]) return nil;
    
    return category;
}

@end

NS_ASSUME_NONNULL_END
