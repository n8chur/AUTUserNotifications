//
//  AUTNotNil.h
//  Automatic
//
//  Created by Robert Böhnke on 08/01/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

#import "metamacros.h"

/// This macro takes multiple nullable references and a single trailing
/// non-nullable reference and returns the first non-null references, starting
/// from the left.
///
/// The return type of the expression will match the last argument in the list.
#define AUTFallback(...) \
    ({ \
        (__typeof(__AUTLastArgument(__VA_ARGS__)))metamacro_foreach_cxt_recursive(__AUTFallback, ?:, metamacro_argcount(__VA_ARGS__), __VA_ARGS__); \
    })

/// This macro allows us to cast a nullable reference to a non-nullable
/// reference that would otherwise trigger a warning if
/// `-Wnullable-to-nonnull-conversion` is enabled.
#define AUTNotNil(V) \
    ({ \
        NSCAssert(V, @"Expected '%@' not to be nil.", @#V); \
        __AUTBox<__typeof(V)> *type; \
        (__typeof(type.asNonNull))V; \
    })

// IMPLEMENTATION DETAILS FOLLOW!
// Do not write code that depends on anything below this line.

#define __AUTFallback(INDEX, LENGTH, ARG) \
    ({ \
        metamacro_if_eq(INDEX, metamacro_dec(LENGTH))(AUTNotNil(ARG))(ARG); \
    })

#define __AUTLastArgument(...) \
    metamacro_at(metamacro_dec(metamacro_argcount(__VA_ARGS__)), __VA_ARGS__)

/// An unimplemented class used to trick the compiler, since a cast along the
/// lines of
///
///     (__nonnull __typeof(bla))bla;
///
/// is not possible.
@interface __AUTBox<__covariant Type>

- (nonnull Type)asNonNull;

@end
