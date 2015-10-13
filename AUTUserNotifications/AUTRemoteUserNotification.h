//
//  AUTRemoteUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotification.h>
#import <AUTUserNotifications/AUTUserNotificationAlertDisplayable.h>

NS_ASSUME_NONNULL_BEGIN

/// An abstract base class representing a notification sent from a server that
/// is either presented to the user or is silent.
///
/// Conforms to MTLJSONSerializing to allow deserialization from the userInfo
/// JSON dictionary sent by the server in the payload of the notification.
///
/// By default, returns self for classForParsingJSONDictionary:. If consumers
/// wish to map remote notifications onto custom subclasses, they should create
/// a base class that all subclasses of this class inherit from, and override
/// classForParsingJSONDictionary: accordingly to specify the correct class to
/// map to for a given JSON dictionary.
///
/// The properties on this class are mapped from the payload of a remote
/// notification, as specified in:
/// https://developer.apple.com/library/prerelease/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1
///
/// The localization key and localization arguments properties support only up
/// to 10 arguments in the format string due to limitations of NSString.
@interface AUTRemoteUserNotification : AUTUserNotification <MTLJSONSerializing, AUTUserNotificationAlertDisplayable>

/// Mapped from "aps.content-available"
@property (readonly, nonatomic, assign, getter=isSilent) BOOL silent;

/// Mapped from "aps.alert.title"
@property (readonly, nonatomic, copy, nullable) NSString *title;

/// Mapped from "aps.alert.title-loc-key"
@property (readonly, nonatomic, copy, nullable) NSString *titleLocalizationKey;

/// Mapped from "aps.alert.title-loc-args"
@property (readonly, nonatomic, copy, nullable) NSArray<NSString *> *titleLocalizationArguments;

/// Mapped from "aps.alert.action-loc-key"
@property (readonly, nonatomic, copy, nullable) NSString *actionLocalizationKey;

/// Mapped from "aps.alert.body"
@property (readonly, nonatomic, copy, nullable) NSString *body;

/// Mapped from "aps.alert.loc-key"
@property (readonly, nonatomic, copy, nullable) NSString *bodyLocalizationKey;

/// Mapped from "aps.alert.loc-args"
@property (readonly, nonatomic, copy, nullable) NSArray<NSString *> *bodyLocalizationArguments;

/// A class method to return the category from the notification dictionary as
/// delivered by the system. This method can be helpful when deciding which
/// class to return in your classForParsingJSONDictionary: for a class cluster.
/// @return the category as a string or nil if the aps dictionary is nil or it
/// does not contain a category key.
+ (nullable NSString *)categoryForJSONDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
