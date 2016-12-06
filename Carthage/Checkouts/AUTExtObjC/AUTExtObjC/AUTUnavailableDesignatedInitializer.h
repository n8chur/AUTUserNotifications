//
//  AUTUnavailableDesignatedInitializer.h
//  Automatic
//
//  Created by Eric Horacek on 10/8/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// An implementation for an unavailable designated initializer to ensure that
/// an exception is thrown if it is invoked.
///
/// An example of its usefulness is with nibs. If marking initWithCoder: as
/// unavailable, it can still be invoked when the object is loaded from a nib.
/// By throwing an exception immediately upon invocation, we ensure failure
/// occurs as early as possible, rather than continuing with undefined behavior.
#define AUT_UNAVAILABLE_DESIGNATED_INITIALIZER \
    { @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Use the designated initializer instead" userInfo:nil]; }

NS_ASSUME_NONNULL_END
