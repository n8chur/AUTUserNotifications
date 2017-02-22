//
//  AUTUserNotificationSpec.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 2/22/17.
//  Copyright © 2017 Automatic Labs. All rights reserved.
//

@import Specta;
@import Expecta;
@import AUTUserNotifications;
#import <AUTUserNotifications/AUTLocalUserNotification_Private.h>
#import <AUTUserNotifications/AUTUserNotificationsViewModel+Stubs.h>

#import "AUTExtObjC.h"

#import "AUTTestLocalUserNotification.h"
#import "AUTTestRootRemoteUserNotification.h"

SpecBegin(AUTUserNotification)

describe(@"-notificationRestoredFromRequest:rootRemoteNotificationClass:", ^{
    it(@"should restore from a local notification request", ^{
        let localNotification = [[AUTTestLocalUserNotification alloc] init];
        let request = [localNotification createNotificationRequest];
        let userNotification = [AUTUserNotification notificationRestoredFromRequest:request rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class];

        expect(userNotification).to.beKindOf(AUTLocalUserNotification.class);
        expect(userNotification).to.equal(localNotification);
    });

    it(@"should restore from a remote notification request", ^{
        let remoteNotification = [[AUTTestRootRemoteUserNotification alloc] init];
        let request = [AUTTestRootRemoteUserNotification asStubNotification].request;
        let userNotification = [AUTUserNotification notificationRestoredFromRequest:request rootRemoteNotificationClass:AUTTestRootRemoteUserNotification.class];

        expect(userNotification).to.beKindOf(AUTRemoteUserNotification.class);
        expect(userNotification).to.equal(remoteNotification);
    });
});

SpecEnd
