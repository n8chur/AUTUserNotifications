//
//  AUTLocalizationNotNeeded.h
//  Automatic
//
//  Created by Eric Horacek on 1/19/17.
//  Copyright © 2017 Automatic Labs. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/// Tells the clang analyzer that this string does not need to be localized (by
/// marking it as localized).
///
/// See http://clang-analyzer.llvm.org/faq.html#unlocalized_string
__attribute__((annotate("returns_localized_nsstring"))) static inline NSString * _Nullable AUTLocalizationNotNeeded(NSString * _Nullable string) {
    return string;
}

NS_ASSUME_NONNULL_END
