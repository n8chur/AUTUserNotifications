//
//  AUTSubclassesOf.c
//  Automatic
//
//  Created by Eric Horacek on 9/29/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import ReactiveObjC;
@import ObjectiveC;

#import "AUTSubclassesOf.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Copied from libextobjc. Only the name of the function was changed.
 *
 * Returns the full list of classes registered with the runtime, terminated with
 * \c NULL. If \a count is not \c NULL, it is filled in with the total number of
 * classes returned. You must \c free() the returned array.
 */
Class *aut_copyClassList (unsigned *count) {
    // get the number of classes registered with the runtime
    int classCount = objc_getClassList(NULL, 0);
    if (!classCount) {
        if (count)
            *count = 0;

        return NULL;
    }

    // allocate space for them plus NULL
    Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
    if (!allClasses) {
        fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
        if (count)
            *count = 0;

        return NULL;
    }

    // and then actually pull the list of the class objects
    classCount = objc_getClassList(allClasses, classCount);
    allClasses[classCount] = NULL;

    @autoreleasepool {
        // weed out classes that do weird things when reflected upon
        for (int i = 0;i < classCount;) {
            Class class = allClasses[i];
            BOOL keep = YES;

            if (keep)
                keep &= class_respondsToSelector(class, @selector(methodSignatureForSelector:));

            if (keep) {
                if (class_respondsToSelector(class, @selector(isProxy)))
                    keep &= ![class isProxy];
            }

            if (!keep) {
                if (--classCount > i) {
                    memmove(allClasses + i, allClasses + i + 1, (classCount - i) * sizeof(*allClasses));
                }

                continue;
            }

            ++i;
        }
    }
    
    if (count)
        *count = (unsigned)classCount;
    
    return allClasses;
}

/**
 * Copied from libextobjc. Only the name of the function was changed.
 *
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a aClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a aClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL. \a aClass may be a metaclass to get
 * all subclass metaclass objects.
 */
Class *aut_copySubclassList (Class targetClass, unsigned *subclassCount) {
    unsigned classCount = 0;
    Class *allClasses = aut_copyClassList(&classCount);
    if (!allClasses || !classCount) {
        fprintf(stderr, "ERROR: No classes registered with the runtime, cannot find %s!\n", class_getName(targetClass));
        return NULL;
    }

    // we're going to reuse allClasses for the return value, so returnIndex will
    // keep track of the indices we replace with new values
    unsigned returnIndex = 0;

    BOOL isMeta = class_isMetaClass(targetClass);

    for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
        Class cls = allClasses[classIndex];
        Class superclass = class_getSuperclass(cls);
        
        while (superclass != NULL) {
            if (isMeta) {
                if (object_getClass(superclass) == targetClass)
                    break;
            } else if (superclass == targetClass)
                break;

            superclass = class_getSuperclass(superclass);
        }

        if (!superclass)
            continue;

        // at this point, 'cls' is definitively a subclass of targetClass
        if (isMeta)
            cls = object_getClass(cls);

        allClasses[returnIndex++] = cls;
    }

    allClasses[returnIndex] = NULL;
    if (subclassCount)
        *subclassCount = returnIndex;
    
    return allClasses;
}

NSArray *aut_subclassesOf(Class targetClass) {
    unsigned subclassCount = 0;
    Class *subclasses = aut_copySubclassList(targetClass, &subclassCount);
    if (subclasses == NULL || subclassCount == 0) return @[];

    @onExit {
        free(subclasses);
    };

    return [NSArray arrayWithObjects:subclasses count:subclassCount];
}

NS_ASSUME_NONNULL_END
