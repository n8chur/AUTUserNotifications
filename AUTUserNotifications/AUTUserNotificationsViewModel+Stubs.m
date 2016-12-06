//
//  AUTUserNotificationsViewModel+Stubs.m
//  AUTUserNotifications
//
//  Created by Eric Horacek on 12/5/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "AUTExtObjC.h"

#import "AUTUserNotificationsViewModel+Stubs.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotificationsViewModel (Stubs)

+ (instancetype)stubViewModelWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions {
    AUTAssertNotNil(rootRemoteNotificationClass);

    let stubAppDelegate = [[AUTStubUserNotificationsAppDelegate alloc] init];

    let stubApplication = [[AUTStubUserNotificationsApplication alloc] initWithDelegate:stubAppDelegate];

    // Return a stub token if registration is attempted.
    stubApplication.remoteNotificationRegistrationDeviceToken = [@"token" dataUsingEncoding:NSUTF8StringEncoding];

    let stubCenter = [[AUTStubUserNotificationCenter alloc] init];

    return [[self alloc]
        initWithCenter:stubCenter
        application:stubApplication
        appDelegate:stubAppDelegate
        rootRemoteNotificationClass:rootRemoteNotificationClass
        defaultPresentationOptions:presentationOptions];
}

@end

NS_ASSUME_NONNULL_END
