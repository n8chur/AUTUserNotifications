//
//  AUTStubUserNotificationsApplication.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/1/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"
#import "AUTUserNotificationsAppDelegate.h"

#import "AUTStubUserNotificationsApplication.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTStubUserNotificationsApplication ()

@property (readonly, nonatomic) id<AUTUserNotificationsAppDelegate> delegate;

@end

@implementation AUTStubUserNotificationsApplication

- (instancetype)init AUT_UNAVAILABLE_DESIGNATED_INITIALIZER;

- (instancetype)initWithDelegate:(id<AUTUserNotificationsAppDelegate>)delegate {
    AUTAssertNotNil(delegate);

    self = [super init];

    _delegate = delegate;

    return self;
}

#pragma mark - Remote Notification Registration

- (void)registerForRemoteNotifications {
    let error = self.remoteNotificationRegistrationError;
    let token = self.remoteNotificationRegistrationDeviceToken;

    if (error != nil) {
        self.isRegisteredForRemoteNotifications = NO;

        [self.delegate
            application:(UIApplication *)NSObject.new
            didFailToRegisterForRemoteNotificationsWithError:error];

    } else if (token != nil) {
        self.isRegisteredForRemoteNotifications = YES;

        [self.delegate
            application:(UIApplication *)NSObject.new
            didRegisterForRemoteNotificationsWithDeviceToken:token];
    } else {
        let reason = @"You must either set an error or token before registering for remote notifications";
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
    }
}

- (void)unregisterForRemoteNotifications {
    self.isRegisteredForRemoteNotifications = NO;
}

- (RACSignal<NSNumber *> *)sendSilentRemoteNotification:(NSDictionary *)remoteNotification {
    let subject = [RACReplaySubject subject];

    [self.delegate
        application:(UIApplication *)NSObject.new
        didReceiveRemoteNotification:remoteNotification
        fetchCompletionHandler:^(UIBackgroundFetchResult result) {
            [subject sendNext:@(result)];
            [subject sendCompleted];
        }];

    return subject;
}

@end

NS_ASSUME_NONNULL_END
