//
//  AUTRemoteUserNotification.h
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import <AUTUserNotifications/AUTUserNotification.h>

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
@interface AUTRemoteUserNotification : AUTUserNotification <MTLJSONSerializing>

/// Mapped from "aps.content-available"
@property (readonly, nonatomic, assign, getter=isSilent) BOOL silent;

/// A class method to return the category from the notification dictionary as
/// delivered by the system. This method can be helpful when deciding which
/// class to return in your classForParsingJSONDictionary: for a class cluster.
/// @return the category as a string or nil if the aps dictionary is nil or it
/// does not contain a category key.
+ (nullable NSString *)categoryForJSONDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
