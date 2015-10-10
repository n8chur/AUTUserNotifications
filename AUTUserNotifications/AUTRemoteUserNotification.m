//
//  AUTRemoteUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveCocoa;

#import "AUTRemoteUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTRemoteUserNotification

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @keypath(AUTRemoteUserNotification.new, silent): @"aps.content-available",
        @keypath(AUTRemoteUserNotification.new, badgeCount): @"aps.badge",
        @keypath(AUTRemoteUserNotification.new, sound): @"aps.sound",
        @keypath(AUTRemoteUserNotification.new, category): @"aps.category",
        @keypath(AUTRemoteUserNotification.new, title): @"aps.alert.title",
        @keypath(AUTRemoteUserNotification.new, titleLocalizationKey): @"aps.alert.title-loc-key",
        @keypath(AUTRemoteUserNotification.new, titleLocalizationArguments): @"aps.alert.title-loc-args",
        @keypath(AUTRemoteUserNotification.new, actionLocalizationKey): @"aps.alert.action-loc-key",
        @keypath(AUTRemoteUserNotification.new, body): @"aps.alert.body",
        @keypath(AUTRemoteUserNotification.new, bodyLocalizationKey): @"aps.alert.loc-key",
        @keypath(AUTRemoteUserNotification.new, bodyLocalizationArguments): @"aps.alert.loc-args",
        @keypath(AUTRemoteUserNotification.new, launchImageFilename): @"aps.alert.launch-image",
    };
}

+ (Class)classForParsingJSONDictionary:(NSDictionary *)JSONDictionary {
    return self;
}

@end

NS_ASSUME_NONNULL_END
