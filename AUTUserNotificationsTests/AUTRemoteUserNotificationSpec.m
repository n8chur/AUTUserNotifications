//
//  AUTRemoteUserNotificationSpec.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Specta;
@import Expecta;
#import <AUTUserNotifications/AUTUserNotifications.h>

#import "AUTRemoteUserNotification.h"

SpecBegin(AUTRemoteUserNotification)

it(@"should map from a remote notification dictionary", ^{
    BOOL contentAvailable = YES;
    NSNumber *badgeCount = @123;
    NSString *sound = @"sound";
    NSString *category = @"category";
    NSString *title = @"title";
    NSString *titleLocalizationKey = @"titleLocalizationKey";
    NSArray<NSString *> *titleLocalizationArguments = @[ @"titleLocalizationArguments" ];
    NSString *actionLocalizationKey = @"actionLocalizationKey";
    NSString *body = @"body";
    NSString *bodyLocalizationKey = @"bodyLocalizationKey";
    NSArray<NSString *> *bodyLocalizationArguments = @[ @"bodyLocalizationArguments" ];
    NSString *launchImageFilename = @"launchImageFilename";

    NSDictionary *dictionary = @{
        @"aps": @{
            @"content-available": @(contentAvailable),
            @"badge": badgeCount,
            @"sound": sound,
            @"category": category,
            @"alert": @{
                @"title": title,
                @"title-loc-key": titleLocalizationKey,
                @"title-loc-args": titleLocalizationArguments,
                @"action-loc-key": actionLocalizationKey,
                @"body": body,
                @"loc-key": bodyLocalizationKey,
                @"loc-args": bodyLocalizationArguments,
                @"launch-image": launchImageFilename,
            },
        },
    };

    NSError *error;
    AUTRemoteUserNotification *notification = [MTLJSONAdapter
        modelOfClass:AUTRemoteUserNotification.class
        fromJSONDictionary:dictionary
        error:&error];

    expect(notification).to.beAnInstanceOf(AUTRemoteUserNotification.class);
    expect(error).to.beNil();

    expect(notification.silent).to.equal(contentAvailable);
    expect(notification.badgeCount).to.equal(badgeCount);
    expect(notification.sound).to.equal(sound);
    expect(notification.category).to.equal(category);
    expect(notification.title).to.equal(title);
    expect(notification.titleLocalizationKey).to.equal(titleLocalizationKey);
    expect(notification.titleLocalizationArguments).to.equal(titleLocalizationArguments);
    expect(notification.actionLocalizationKey).to.equal(actionLocalizationKey);
    expect(notification.body).to.equal(body);
    expect(notification.bodyLocalizationKey).to.equal(bodyLocalizationKey);
    expect(notification.bodyLocalizationArguments).to.equal(bodyLocalizationArguments);
    expect(notification.launchImageFilename).to.equal(launchImageFilename);
    
#pragma mark - AUTUserNotificationAlertDisplayable

    expect(notification.localizedBody).to.equal(bodyLocalizationKey);
    expect(notification.localizedTitle).to.equal(titleLocalizationKey);
    expect(notification.localizedAction).to.equal(actionLocalizationKey);
});

SpecEnd
