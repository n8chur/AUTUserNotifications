//
//  AUTUserNotificationAlertDisplayable.h
//  AUTUserNotifications
//
//  Created by Engin Kurutepe on 09/10/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/// AUTUserNotificationAlertDisplayable defines several basic properties which
/// can be used to populate the UI when presenting a notification to the user.
/// Both AUTLocalUserNotification or AUTRemoteNotification conform to this
/// protocol.
@protocol AUTUserNotificationAlertDisplayable <NSObject>

@property (readonly, nonatomic, copy, nullable) NSNumber *badgeCount;

@property (readonly, nonatomic, copy, nullable) NSString *sound;

@property (readonly, nonatomic, copy, nullable) NSString *category;

@property (readonly, nonatomic, copy, nullable) NSString *localizedTitle;

@property (readonly, nonatomic, copy, nullable) NSString *localizedBody;

@property (readonly, nonatomic, copy, nullable) NSString *localizedAction;

@property (readonly, nonatomic, copy, nullable) NSString *launchImageFilename;

@end

NS_ASSUME_NONNULL_END
