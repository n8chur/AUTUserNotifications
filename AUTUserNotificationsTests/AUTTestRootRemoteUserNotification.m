//
//  AUTTestRootRemoteUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTTestChildRemoteUserNotification.h"
#import "AUTAnotherTestChildRemoteUserNotification.h"

#import "AUTTestRootRemoteUserNotification.h"

NS_ASSUME_NONNULL_BEGIN

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

+ (NSDictionary *)asJSONDictionary {
    return @{
        @"aps": @{
            @"category": self.systemCategoryIdentifier
        }
    };
}

@end

NS_ASSUME_NONNULL_END
