//
//  AUTStrongifyOr.h
//  Automatic
//
//  Created by Eric Horacek on 3/29/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "metamacros.h"

/// Same as @strongify, but with an escape hatch if strongification fails.
///
/// @code
///
/// @strongifyOr(self) return [RACSignal empty];
///
/// @endcode
#define strongifyOr(...) \
    aut_keywordify \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    metamacro_foreach(aut_strongify_,, __VA_ARGS__) \
    _Pragma("clang diagnostic pop") \
    if (metamacro_foreach(__AUTIsNotNil,, __VA_ARGS__) true) {} else \

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.

#define __AUTIsNotNil(INDEX, EXPRESSION) \
    (EXPRESSION != nil) &&

#define aut_strongify_(INDEX, VAR) \
    __strong __typeof__(VAR) VAR = metamacro_concat(VAR, _weak_);

// Details about the choice of backing keyword:
//
// The use of @try/@catch/@finally can cause the compiler to suppress
// return-type warnings.
// The use of @autoreleasepool {} is not optimized away by the compiler,
// resulting in superfluous creation of autorelease pools.
//
// Since neither option is perfect, and with no other alternatives, the
// compromise is to use @autorelease in DEBUG builds to maintain compiler
// analysis, and to use @try/@catch otherwise to avoid insertion of unnecessary
// autorelease pools.
#if DEBUG
#define aut_keywordify autoreleasepool {}
#else
#define aut_keywordify try {} @catch (...) {}
#endif
