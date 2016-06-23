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
#import <AUTUserNotifications/AUTLocalUserNotification_Private.h>

#import "AUTTestLocalUserNotification.h"

SpecBegin(AUTLocalUserNotification)

describe(@"unarchiving from a system notification", ^{
    it(@"should restore successfully", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        notification.fireDate = [NSDate date];

        UILocalNotification *systemNotification = [notification createSystemNotification];

        AUTTestLocalUserNotification *restoredNotification = (AUTTestLocalUserNotification *)[AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beKindOf(AUTTestLocalUserNotification.class);
        expect(restoredNotification.fireDate).to.equal(notification.fireDate);
    });

    it(@"should handle user info being nil", ^{
        UILocalNotification *systemNotification = [[UILocalNotification alloc] init];

        AUTLocalUserNotification *restoredNotification = [AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beNil();
    });

    it(@"should handle user info not containing the expected key", ^{
        UILocalNotification *systemNotification = [[UILocalNotification alloc] init];
        systemNotification.userInfo = @{};

        AUTLocalUserNotification *restoredNotification = [AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beNil();
    });

    it(@"should handle unarchiving an invalid class", ^{
        UILocalNotification *systemNotification = [[UILocalNotification alloc] init];

        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:[NSDate date] forKey:NSKeyedArchiveRootObjectKey];
        [archiver finishEncoding];

        systemNotification.userInfo = @{
            AUTLocalUserNotificationKey: [data copy],
        };

        AUTLocalUserNotification *restoredNotification = [AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beNil();
    });

    it(@"should catch exceptions that occur while unarchiving an invalid class", ^{
        AUTTestLocalUserNotification *notification = [[AUTTestLocalUserNotification alloc] init];
        notification.fireDate = [NSDate date];

        UILocalNotification *systemNotification = [[UILocalNotification alloc] init];

        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setClassName:@"AUTInvalidClass" forClass:AUTTestLocalUserNotification.class];
        [archiver encodeObject:notification forKey:NSKeyedArchiveRootObjectKey];
        [archiver finishEncoding];

        systemNotification.userInfo = @{
            AUTLocalUserNotificationKey: [data copy],
        };

        AUTLocalUserNotification *restoredNotification = [AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beNil();
    });

    it(@"should fail restoration if the subclass desires", ^{
        AUTTestLocalRestorationFailureUserNotification *notification = [[AUTTestLocalRestorationFailureUserNotification alloc] init];
        UILocalNotification *systemNotification = [notification createSystemNotification];

        AUTLocalUserNotification *restoredNotification = [AUTLocalUserNotification
            notificationRestoredFromSystemNotification:systemNotification
            withActionIdentifier:nil
            systemActionCompletionHandler:^{}];

        expect(restoredNotification).to.beNil();
    });
});

SpecEnd
