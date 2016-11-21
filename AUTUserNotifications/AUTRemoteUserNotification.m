//
//  AUTRemoteUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;

#import "AUTRemoteUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTRemoteUserNotification ()

/// Mapped from "aps.badge"
@property (readwrite, nonatomic, copy, nullable) NSNumber *badgeCount;

/// Mapped from "aps.sound"
@property (readwrite, nonatomic, copy, nullable) NSString *sound;

/// Mapped from "aps.category"
@property (readwrite, nonatomic, copy, nullable) NSString *category;

/// Mapped from "aps.alert.launch-image"
@property (readwrite, nonatomic, copy, nullable) NSString *launchImageFilename;

@end

@implementation AUTRemoteUserNotification

@synthesize badgeCount = _badgeCount;
@synthesize sound = _sound;
@synthesize category = _category;
@dynamic localizedTitle, localizedBody, localizedAction;
@synthesize launchImageFilename = _launchImageFilename;

#pragma mark - AUTRemoteUserNotification <MTLJSONSerializing>

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

+ (nullable NSString *)categoryForJSONDictionary:(NSDictionary *)JSONDictionary {
    NSDictionary *aps = JSONDictionary[@"aps"];
    if (aps == nil || ![aps isKindOfClass:NSDictionary.class]) return nil;
    
    NSString *category = aps[@"category"];
    if (category == nil || ![category isKindOfClass:NSString.class]) return nil;
    
    return category;
}

#pragma mark - AUTUserNotificationAlertDisplayable

- (nullable NSString *)localizedBody {
    if (self.bodyLocalizationKey != nil) {
        NSString *localizedBodyFormat = NSLocalizedString(self.bodyLocalizationKey, nil);
        
        if (self.bodyLocalizationArguments != nil) {
            localizedBodyFormat = [self localizedStringWithFormat:localizedBodyFormat arguments:self.bodyLocalizationArguments];
        }
        
        return localizedBodyFormat;
    }
    
    return self.body;
}

- (nullable NSString *)localizedTitle {
    if (self.titleLocalizationKey != nil) {
        NSString *localizedTitleFormat = NSLocalizedString(self.titleLocalizationKey, nil);
        
        if (self.titleLocalizationArguments != nil) {
            localizedTitleFormat = [self localizedStringWithFormat:localizedTitleFormat arguments:self.titleLocalizationArguments];
        }
        
        return localizedTitleFormat;
    }
    
    return self.title;
}

- (nullable NSString *)localizedAction {
    if (self.actionLocalizationKey != nil) {
        return NSLocalizedString(self.actionLocalizationKey, nil);
    }
    
    return nil;
}

#pragma mark Private

// Adapted from https://github.com/ParsePlatform/Parse-SDK-iOS-OSX/blob/e2bed4df96566febcc80d11f340c15475623cbef/Parse/Internal/PFInternalUtils.m#L259
- (nullable NSString *)localizedStringWithFormat:(NSString *)format arguments:(NSArray *)arguments {
    // We cannot reliably construct a va_list for 64-bit, so hard code up to N args.
    const int maxNumArgs = 10;
    NSAssert(arguments.count <= maxNumArgs, @"Maximum of %d format args allowed", maxNumArgs);
    NSMutableArray *args = [arguments mutableCopy];
    for (NSUInteger i = arguments.count; i < maxNumArgs; i++) {
        [args addObject:@""];
    }
    return [NSString stringWithFormat:format,
            args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]];
}

#pragma mark - MTLModel

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    if ([propertyKey isEqualToString:@keypath(AUTRemoteUserNotification.new, systemFetchCompletionHandler)]) {
        return MTLPropertyStorageNone;
    }

    return [super storageBehaviorForPropertyWithKey:propertyKey];
}

@end

NS_ASSUME_NONNULL_END
