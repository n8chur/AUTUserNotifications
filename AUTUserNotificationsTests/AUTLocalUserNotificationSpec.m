//
//  AUTLocalUserNotificationSpec.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 6/22/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import Specta;
@import Expecta;
#import <AUTUserNotifications/AUTUserNotifications.h>
#import <AUTUserNotifications/AUTUserNotification_Private.h>
#import <AUTUserNotifications/AUTLocalUserNotification_Private.h>

#import "AUTExtObjC.h"

#import "AUTTestLocalUserNotification.h"

SpecBegin(AUTLocalUserNotification)

describe(@"unarchiving from a system notification", ^{
    it(@"should restore successfully", ^{
        let notification = [[AUTTestLocalUserNotification alloc] init];
        let request = [notification createNotificationRequest];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];
            
        expect(restoredNotification).to.beKindOf(AUTTestLocalUserNotification.class);
        expect(restoredNotification).to.equal(notification);
    });

    it(@"should handle user info being nil", ^{
        let content = [[UNNotificationContent alloc] init];
        let trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        let request = [UNNotificationRequest requestWithIdentifier:@"ID" content:content trigger:trigger];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];

        expect(restoredNotification).to.beNil();
    });

    it(@"should handle user info not containing the expected key", ^{
        let content = [[UNMutableNotificationContent alloc] init];
        content.userInfo = @{};

        let trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        let request = [UNNotificationRequest requestWithIdentifier:@"ID" content:content trigger:trigger];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];

        expect(restoredNotification).to.beNil();
    });

    it(@"should handle unarchiving an invalid class", ^{
        let content = [[UNMutableNotificationContent alloc] init];

        let data = [NSMutableData data];
        let archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:[NSDate date] forKey:NSKeyedArchiveRootObjectKey];
        [archiver finishEncoding];

        content.userInfo = @{
            AUTLocalUserNotificationKey: [data copy],
        };

        let trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        let request = [UNNotificationRequest requestWithIdentifier:@"ID" content:content trigger:trigger];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];

        expect(restoredNotification).to.beNil();
    });

    it(@"should catch exceptions that occur while unarchiving an invalid class", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];

        let content = [[UNMutableNotificationContent alloc] init];

        let data = [NSMutableData data];
        let archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setClassName:@"AUTInvalidClass" forClass:AUTTestLocalUserNotification.class];
        [archiver encodeObject:notification forKey:NSKeyedArchiveRootObjectKey];
        [archiver finishEncoding];

        content.userInfo = @{
            AUTLocalUserNotificationKey: [data copy],
        };

        let trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        let request = [UNNotificationRequest requestWithIdentifier:@"ID" content:content trigger:trigger];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];

        expect(restoredNotification).to.beNil();
    });

    it(@"should fail restoration if the subclass desires", ^{
        let notification = [[AUTTestLocalRestorationFailureUserNotification alloc] init];
        let request = [notification createNotificationRequest];

        let restoredNotification = [AUTUserNotification
            notificationRestoredFromRequest:request
            rootRemoteNotificationClass:AUTRemoteUserNotification.class];

        expect(restoredNotification).to.beNil();
    });
});

SpecEnd
