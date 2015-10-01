//
//  AUTSubclassesOf.h
//  Automatic
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/// Returns the classes that descend from the specified class, or an empty array
/// if there are none.
NSArray *aut_subclassesOf(Class targetClass);

NS_ASSUME_NONNULL_END
