//
//  AUTAssertNotNil.h
//  Automatic
//
//  Created by Robert Böhnke on 05/01/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "metamacros.h"

/// Asserts that all expressions passed to the macro are not `nil`.
#define AUTAssertNotNil(...) \
    do { \
        metamacro_foreach(__AUTAssertNotNil,,__VA_ARGS__) \
    } while(0)

/// Asserts that all expressions passed to the macro are not `nil`.
#define AUTCAssertNotNil(...) \
do { \
metamacro_foreach(__AUTCAssertNotNil,,__VA_ARGS__) \
} while(0)

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.

#define __AUTAssertNotNil(INDEX, EXPRESSION) \
    NSParameterAssert(EXPRESSION != nil);

#define __AUTCAssertNotNil(INDEX, EXPRESSION) \
    NSCParameterAssert(EXPRESSION != nil);
