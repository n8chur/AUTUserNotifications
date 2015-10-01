//
//  AUTUserNotification.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

#import "AUTUserNotification_Private.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AUTUserNotification

+ (NSString *)systemCategoryIdentifier {
    return NSStringFromClass(self);
}

+ (nullable UIUserNotificationCategory *)systemCategory {
    UIMutableUserNotificationCategory *category = [[UIMutableUserNotificationCategory alloc] init];

    category.identifier = self.class.systemCategoryIdentifier;

    NSMutableDictionary<NSNumber *, NSArray <UIUserNotificationAction *> *> *actionsByContext = [NSMutableDictionary dictionary];

    for (NSNumber *context in @[ @(UIUserNotificationActionContextDefault), @(UIUserNotificationActionContextMinimal) ]) {
        NSArray<UIUserNotificationAction *> *actions = [self systemActionsForContext:context.unsignedIntegerValue];
        if (actions == nil || actions.count == 0) continue;

        actionsByContext[context] = actions;
    }

    // If there are no actions, do not create a category.
    if (actionsByContext.count == 0) return nil;

    // Otherwise, register the actions and return the category.
    [actionsByContext enumerateKeysAndObjectsUsingBlock:^(NSNumber *context, NSArray<UIUserNotificationAction *> *actions, BOOL *_) {
        [category setActions:actions forContext:context.unsignedIntegerValue];
    }];

    return [category copy];
}

+ (nullable NSArray<UIUserNotificationAction *> *)systemActionsForContext:(UIUserNotificationActionContext)context {
    // Subclases override this method.
    return nil;
}

@end

NS_ASSUME_NONNULL_END
