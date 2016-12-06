//
//  AUTAutoType.h
//  Automatic
//
//  Created by Eric Horacek on 10/20/16.
//  Copyright © 2016 Automatic Labs. All rights reserved.
//

/// Swifty versions of __auto_type.
///
/// See:
/// - https://gcc.gnu.org/onlinedocs/gcc/Typeof.html
/// - https://reviews.llvm.org/D12686

#define let __auto_type const

#define var __auto_type
