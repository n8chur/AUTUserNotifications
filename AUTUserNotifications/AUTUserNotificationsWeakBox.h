//
//  AUTUserNotificationsWeakBox.h
//  AUTUserNotifications
//
//  Created by Eric Horacek on 5/9/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

@import Mantle;

NS_ASSUME_NONNULL_BEGIN

/// A box with a weak boxed value.
///
/// Exists because -[NSValue nonretainedObjectValue] does not clear out its
/// boxed value, which can lead to crashes.
///
/// Inherits from MTLModel for free equality comparisons and hashing on the
/// value of the box.
@interface AUTUserNotificationsWeakBox<__covariant BoxType> : MTLModel

- (instancetype)initWithValue:(nullable __weak BoxType)value;

+ (instancetype)box:(nullable __weak BoxType)value;

/// The weakly referenced boxed value.
@property (nonatomic, readonly, weak, nullable) BoxType value;

@end

NS_ASSUME_NONNULL_END
