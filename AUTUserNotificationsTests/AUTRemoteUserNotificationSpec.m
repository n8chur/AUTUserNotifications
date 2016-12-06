//
//  AUTRemoteUserNotificationSpec.m
//  Automatic
//
//  Created by Eric Horacek on 9/28/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Specta;
@import Expecta;
@import AUTUserNotifications;

#import "AUTExtObjC.h"

SpecBegin(AUTRemoteUserNotification)

it(@"should map from a remote notification dictionary", ^{
    let contentAvailable = YES;

    let dictionary = @{
        @"aps": @{
            @"content-available": @(contentAvailable),
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
});

SpecEnd
