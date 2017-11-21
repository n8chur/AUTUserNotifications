//
//  AUTUserNotificationsViewModel.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Mantle;
@import ReactiveObjC;

#import "UNUserNotificationCenter+AUTSynthesizedCategories.h"

#import "AUTLog.h"
#import "AUTUserNotificationsAppDelegate.h"
#import "AUTUserNotificationCenter.h"
#import "AUTUNAuthorizationOptionsDescription.h"
#import "AUTUNNotificationPresentationOptionsDescription.h"
#import "AUTRemoteUserNotificationTokenRegistrar.h"
#import "AUTUserNotificationActionHandler.h"
#import "AUTRemoteUserNotificationFetchHandler.h"
#import "AUTExtObjC.h"
#import "AUTUserNotification_Private.h"
#import "AUTLocalUserNotification_Private.h"
#import "AUTRemoteUserNotification_Private.h"

#import "AUTUserNotificationsViewModel_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTUserNotificationsViewModel () <UNUserNotificationCenterDelegate> {
    RACSubject<__kindof AUTUserNotification *> *_respondedNotifications;
    RACSubject<__kindof AUTUserNotification *> *_presentedNotifications;
    RACSubject<__kindof AUTRemoteUserNotification *> *_receivedSilentRemoteNotifications;

    /// Should only be mutated while synchronized on self.
    NSMutableArray<AUTUserNotificationPresentationOverride> *_presentationOverrides;
}

@property (readonly, nonatomic, copy) NSArray<AUTUserNotificationPresentationOverride> *presentationOverrides;

/// A scheduler on which to test presentation overrides so that they are not run
/// on the main thread.
@property (readonly, nonatomic) RACScheduler *presentationOverrideScheduler;

/// A map table with keys of references to registered fetch handlers and values
/// of the set of notification classes that the fetch handler is registered for.
///
/// Should only be used while synchronized on `self`.
@property (nonatomic, readonly) NSMapTable<id<AUTRemoteUserNotificationFetchHandler>, NSSet<Class> *> *fetchHandlers;

/// A map table with key of references to registered action handlers, and values
/// of the set of notification classes that the action handler is registered for.
///
/// Should only be used while synchronized on `self`.
@property (nonatomic, readonly) NSMapTable<id<AUTUserNotificationActionHandler>, NSSet<Class> *> *actionHandlers;

@property (readonly, nonatomic) NSObject<AUTUserNotificationsApplication> *application;
@property (readonly, nonatomic) NSObject<AUTUserNotificationsAppDelegate> *appDelegate;
@property (readonly, nonatomic) UNNotificationPresentationOptions defaultPresentationOptions;

@end

@implementation AUTUserNotificationsViewModel

- (instancetype)init AUT_UNAVAILABLE_DESIGNATED_INITIALIZER;

- (instancetype)initWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions {
    AUTAssertNotNil(rootRemoteNotificationClass);

    let center = UNUserNotificationCenter.currentNotificationCenter;
    let application = UIApplication.sharedApplication;
    let appDelegate = (id<AUTUserNotificationsAppDelegate>)UIApplication.sharedApplication.delegate;
    NSAssert([appDelegate conformsToProtocol:@protocol(AUTUserNotificationsAppDelegate)], @"You must confrom your %@ to %@ to initialize a %@.", NSStringFromProtocol(@protocol(UIApplicationDelegate)), NSStringFromProtocol(@protocol(AUTUserNotificationsAppDelegate)), self.class);

    [center aut_setSynthesizedCategories];

    return [self initWithCenter:center application:application appDelegate:appDelegate rootRemoteNotificationClass:rootRemoteNotificationClass defaultPresentationOptions:presentationOptions];
}

- (instancetype)initWithCenter:(id<AUTUserNotificationCenter>)center application:(id<AUTUserNotificationsApplication>)application appDelegate:(id<AUTUserNotificationsAppDelegate>)appDelegate rootRemoteNotificationClass:(Class)rootRemoteNotificationClass defaultPresentationOptions:(UNNotificationPresentationOptions)presentationOptions {
    AUTAssertNotNil(center, application, appDelegate, rootRemoteNotificationClass);
    NSAssert([rootRemoteNotificationClass isSubclassOfClass:AUTRemoteUserNotification.class], @"The rootRemoteNotificationClass %@ must descend from %@", rootRemoteNotificationClass, AUTRemoteUserNotification.class);

    self = [super init];

    _center = center;
    _center.delegate = self;

    _application = application;
    _appDelegate = appDelegate;
    _rootRemoteNotificationClass = rootRemoteNotificationClass;
    _defaultPresentationOptions = presentationOptions;

    _presentationOverrides = [NSMutableArray array];
    _actionHandlers = [NSMapTable weakToStrongObjectsMapTable];
    _fetchHandlers = [NSMapTable weakToStrongObjectsMapTable];

    let schedulerName = @"com.automatic.AUTUserNotifications.presentationOverrideTestScheduler";
    _presentationOverrideScheduler = [RACScheduler schedulerWithPriority:RACSchedulerPriorityHigh name:schedulerName];

    _respondedNotifications = [[RACSubject subject] setNameWithFormat:@"-respondedNotifications"];
    [self.rac_willDeallocSignal subscribe:_respondedNotifications];
    [self performActionsForRespondedNotifications:_respondedNotifications];

    // Share a subscription to presented notifications.
    _presentedNotifications = [[RACSubject subject] setNameWithFormat:@"-presentedNotifications"];
    [self.rac_willDeallocSignal subscribe:_presentedNotifications];

    // Share a subscription to received silent remote notifications.
    _receivedSilentRemoteNotifications = [[RACSubject subject] setNameWithFormat:@"-receivedSilentRemoteNotifications"];
    [[self createReceivedSilentRemoteNotifications] subscribe:_receivedSilentRemoteNotifications];
    [self.rac_willDeallocSignal subscribe:_receivedSilentRemoteNotifications];
    [self performFetchesForSilentRemoteNotifications:_receivedSilentRemoteNotifications];

    _requestAuthorization = [self createRequestAuthorizationCommand];
    _registerForRemoteNotifications = [self createRegisterForRemoteNotificationsCommand];

    return self;
}

#pragma mark - Authorization

- (RACCommand<NSNumber *, UNNotificationSettings *> *)createRequestAuthorizationCommand {
    @weakify(self);

    return [[RACCommand alloc] initWithSignalBlock:^ RACSignal<UNNotificationSettings *> * (NSNumber *options) {
        @strongifyOr(self) return [RACSignal empty];
        AUTCAssertNotNil(options);

        return [[self requestRequestAuthorizationWithOptions:options.unsignedIntegerValue]
            flattenMap:^ RACSignal<UNNotificationSettings *> * (NSNumber *granted) {
                @strongifyOr(self) return [RACSignal empty];

                return [self.settings doNext:^(UNNotificationSettings *settings) {
                    AUTLogUserNotificationInfo(@"%@ authorization request granted %@ from options %@ with system as settings %@", self_weak_, granted.boolValue ? @"YES" : @"NO", AUTUNAuthorizationOptionsDescription(options.unsignedIntegerValue), settings);
                }];
            }];
    }];
}

- (RACSignal<NSNumber *> *)requestRequestAuthorizationWithOptions:(UNAuthorizationOptions)options {
    @weakify(self);

    return [RACSignal createSignal:^ RACDisposable * _Nullable (id<RACSubscriber> subscriber) {
        @strongifyOr(self) {
            [subscriber sendCompleted];
            return nil;
        }

        AUTLogUserNotificationInfo(@"%@ requesting authorization of options with system %@", self_weak_, AUTUNAuthorizationOptionsDescription(options));

        [self.center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
            @strongifyOr(self) {
                [subscriber sendCompleted];
                return;
            }

            if (error != nil) {
                AUTLogUserNotificationError(@"%@ error requesting authorization of options %@ with system %@", self_weak_, AUTUNAuthorizationOptionsDescription(options), error);

                [subscriber sendError:error];
                return;
            }

            [subscriber sendNext:@(granted)];
            [subscriber sendCompleted];
        }];

        return nil;
    }];
}

- (RACSignal<UNNotificationSettings *> *)settings {
    @weakify(self);

    return [RACSignal createSignal:^ RACDisposable * _Nullable (id<RACSubscriber> _Nonnull subscriber) {
        @strongifyOr(self) {
            [subscriber sendCompleted];
            return nil;
        }

        [self.center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
            [subscriber sendNext:settings];
            [subscriber sendCompleted];
        }];

        return nil;
    }];
}

#pragma mark - Tokens

/// Sends the next registered device token or else errors.
- (RACSignal<NSData *> *)registeredDeviceTokens {
    @weakify(self);

    RACSignal<NSData *> *token = [[[self.appDelegate
        rac_signalForSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) fromProtocol:@protocol(AUTUserNotificationsAppDelegate)]
        reduceEach:^(id _, NSData *deviceToken){
            return deviceToken;
        }]
        doNext:^(NSData *token) {
            AUTLogUserNotificationInfo(@"%@ received device token from system %@", self_weak_, token);
        }];

    RACSignal *errors = [[[[self.appDelegate
        rac_signalForSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) fromProtocol:@protocol(AUTUserNotificationsAppDelegate)]
        reduceEach:^(id _, NSError *error){
            return [RACSignal error:error];
        }]
        flatten]
        doError:^(NSError *error) {
            AUTLogUserNotificationError(@"%@ received error requesting device token from system %@", self_weak_, error);
        }];

    return [[RACSignal merge:@[ token, errors ]]
        // Complete immediately if a token is sent.
        take:1];
}

/// Upon subscription, issues a device token and registers it with APNS. Sends
/// the resulting device token upon success or errors otherwise.
- (RACSignal<NSData *> *)issueDeviceToken {
    @weakify(self);

    return [RACSignal createSignal:^ RACDisposable * _Nullable (id<RACSubscriber> subscriber) {
        @strongifyOr(self) {
            [subscriber sendCompleted];
            return nil;
        }

        let disposable = [[self registeredDeviceTokens]
            subscribe:subscriber];

        AUTLogUserNotificationInfo(@"%@ requesting device token from system...", self);

        // Register after subscription to prevent races.
        [self.application registerForRemoteNotifications];

        return disposable;
    }];
}

- (RACSignal *)registerDeviceTokenWithServer:(NSData *)token usingRegistrar:(id<AUTRemoteUserNotificationTokenRegistrar>)registrar {
    AUTAssertNotNil(token, registrar);

    @weakify(self);

    let registerDeviceToken = [registrar registerDeviceToken:token];
    NSAssert(registerDeviceToken != nil, @"%@ %@ must return a signal", registrar, NSStringFromSelector(@selector(registerDeviceToken:)));

    return [[registerDeviceToken
        initially:^{
            AUTLogUserNotificationInfo(@"%@ registering token %@ with registrar %@...", self_weak_, token, registrar);
        }]
        doCompleted:^{
            AUTLogUserNotificationInfo(@"%@ successfully registered token %@ with registrar %@...", self_weak_, token, registrar);
        }];
}

- (RACCommand<id<AUTRemoteUserNotificationTokenRegistrar>, id> *)createRegisterForRemoteNotificationsCommand {
    @weakify(self);

    return [[RACCommand alloc] initWithSignalBlock:^(id<AUTRemoteUserNotificationTokenRegistrar> registrar) {
        @strongifyOr(self) return [RACSignal empty];
        AUTCAssertNotNil(registrar);

        return [[[self issueDeviceToken]
            flattenMap:^(NSData *deviceToken) {
                @strongifyOr(self) return [RACSignal empty];
                return [self registerDeviceTokenWithServer:deviceToken usingRegistrar:registrar];
            }]
            ignoreValues];
    }];
}

#pragma mark - Silent Remote Notifications

#pragma mark Public

- (RACDisposable *)registerFetchHandler:(id<AUTRemoteUserNotificationFetchHandler>)fetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert(fetchHandler != nil);
    NSParameterAssert(notificationClass != nil);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTRemoteUserNotification.class]);

    [self addFetchHandler:fetchHandler forRemoteUserNotificationsOfClass:notificationClass];

    @weakify(self, fetchHandler);
    return [RACDisposable disposableWithBlock:^{
        @strongify(self, fetchHandler);

        [self removeFetchHandler:fetchHandler forRemoteUserNotificationsOfClass:notificationClass];
    }];
}

#pragma mark Private

- (RACSignal<__kindof AUTRemoteUserNotification *> *)createReceivedSilentRemoteNotifications {
    @weakify(self);

    return [[self.appDelegate rac_signalForSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:) fromProtocol:@protocol(AUTUserNotificationsAppDelegate)]
        reduceEach:^ AUTRemoteUserNotification * (id _, NSDictionary *dictionary, void (^fetchCompletionHandler)(UIBackgroundFetchResult)){
            @strongifyOr(self) return nil;

            let notification = [self.rootRemoteNotificationClass notificationRestoredFromDictionary:dictionary];
            if (notification == nil) {
                AUTLogUserNotificationInfo(@"%@ unable to create remote notification, calling completion handler", self_weak_);
                fetchCompletionHandler(UIBackgroundFetchResultNoData);
                return nil;
            }

            notification.systemFetchCompletionHandler = fetchCompletionHandler;
            return notification;
        }];
}

/// For each sent silent remote notification sent over the specified signal,
/// performs a fetch for each of the registered fetch handlers with the
/// notification. Upon completion of all fetches, invokes the
/// fetchCompletionHandler property on the sent notification with the worst
/// of the fetch results.
- (RACDisposable *)performFetchesForSilentRemoteNotifications:(RACSignal<__kindof AUTRemoteUserNotification *> *)receivedSilentRemoteNotifications {
    AUTAssertNotNil(receivedSilentRemoteNotifications);

    @weakify(self);

    return [[receivedSilentRemoteNotifications
        flattenMap:^(__kindof AUTRemoteUserNotification *notification) {
            @strongifyOr(self) return [RACSignal empty];

            NSCAssert(notification.systemFetchCompletionHandler != nil, @"Silent remote notifications must have a fetch completion handler: %@", notification);

            return [[[self combinedFetchHandlerSignalsForSilentRemoteNotification:notification]
                initially:^{
                    AUTLogUserNotificationInfo(@"%@ performing fetch for silent remote notification: <%@: %p>", self_weak_, notification.class, &notification);
                }]
                doCompleted:^{
                    AUTLogUserNotificationInfo(@"%@ finished performing fetch for silent remote notification: <%@: %p>", self_weak_, notification.class, notification);
                }];
        }]
        subscribeError:^(NSError *error) {
            let reason = [NSString stringWithFormat:@"%@ -performFetchesForSilentRemoteNotifications errored due to programmer error: %@", self_weak_, error];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }];
}

- (RACSignal *)combinedFetchHandlerSignalsForSilentRemoteNotification:(AUTRemoteUserNotification *)notification {
    AUTAssertNotNil(notification);

    NSArray <id<AUTRemoteUserNotificationFetchHandler>> *handlers = [self fetchHandlersForSilentRemoteNotification:notification];

    @weakify(self);

    // If there were no fetch handlers for the notification, invoke the fetch
    // completion handler with NoData and complete.
    if (handlers.count == 0) {
        return [RACSignal defer:^{
            AUTLogUserNotificationInfo(@"%@ no handlers for notification <%@: %p>, invoking completion handler", self_weak_, notification.class, notification);

            notification.systemFetchCompletionHandler(UIBackgroundFetchResultNoData);
            notification.systemFetchCompletionHandler = nil;

            return [RACSignal empty];
        }];
    }

    // Otherwise, invoke all fetch handlers and collect results into an array of
    // RACSignals representing all work that should be done as a result of this
    // notification.
    NSArray<RACSignal<NSNumber *> *> *fetchHandlerSignals = [handlers.rac_sequence map:^(id<AUTRemoteUserNotificationFetchHandler> handler) {
        return [self performFetchForNotification:notification withHandler:handler];
    }].array;

    return [[[[RACSignal merge:fetchHandlerSignals]
        // Wait for all fetch handlers to complete and send their statuses.
        collect]
        // Find the "worst" returned status of all handlers.
        map:^(NSArray<NSNumber *> *backgroundRefreshResults) {
            // Sorts the statuses in the order of NewData, NoData, Failed.
            let sortedStatues = [backgroundRefreshResults sortedArrayUsingSelector:@selector(compare:)];

            // The last status is the "worst", so send it.
            return sortedStatues.lastObject;
        }]
        // Invoke the system completion handler with the "worst" status
        // resulting from all registered handlers.
        doNext:^(NSNumber *worstStatus) {
            AUTLogUserNotificationInfo(@"%@ all action handlers completed for notification <%@: %p>, invoking completion handler with status: %@", self_weak_, notification.class, notification, worstStatus);

            notification.systemFetchCompletionHandler(worstStatus.unsignedIntegerValue);
            notification.systemFetchCompletionHandler = nil;
        }];
}

- (RACSignal *)performFetchForNotification:(AUTRemoteUserNotification *)notification withHandler:(id<AUTRemoteUserNotificationFetchHandler>)handler {
    AUTAssertNotNil(notification, handler);

    __block BOOL didSendValidValue = NO;
    @weakify(handler);

    let performFetch = [handler performFetchForNotification:notification];
    NSAssert(performFetch != nil, @"%@ %@ must return a signal", handler, NSStringFromSelector(@selector(performFetchForNotification:)));

    return [[[performFetch
        doNext:^(NSNumber *refreshResult) {
            NSCAssert(!didSendValidValue, @"%@ -performFetchForNotification: %@ must only send one next value, instead received: %@", handler_weak_, notification, refreshResult);
            NSCAssert([refreshResult isKindOfClass:NSNumber.class], @"%@ -performFetchForNotification: %@ must send an NSNumber, instead received: %@", handler_weak_, notification, refreshResult);

            switch ((UIBackgroundFetchResult)refreshResult.unsignedIntegerValue) {
            case UIBackgroundFetchResultNewData:
            case UIBackgroundFetchResultNoData:
            case UIBackgroundFetchResultFailed:
                didSendValidValue = YES;
                return;
            }

            let reason = [NSString stringWithFormat:@"%@ -performFetchForNotification: %@ sent an invalid refresh result: %@", handler_weak_, notification, refreshResult];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }]
        doError:^(NSError *error) {
            NSCAssert(error, @"%@ -performFetchForNotification: %@ errored: %@. All errors must be caught.", handler_weak_, notification, error);
        }]
        doCompleted:^{
            NSCAssert(didSendValidValue, @"%@ -performFetchForNotification: %@ must send a UIBackgroundFetchResult before completing", handler_weak_, notification);
        }];
}

#pragma mark - Fetch Handlers

- (NSArray <id<AUTRemoteUserNotificationFetchHandler>> *)fetchHandlersForSilentRemoteNotification:(AUTRemoteUserNotification *)notification {
    NSParameterAssert(notification != nil);

    NSMutableSet<id<AUTRemoteUserNotificationFetchHandler>> *handlers = [NSMutableSet set];

    @synchronized (self) {
        for (id<AUTRemoteUserNotificationFetchHandler> handler in self.fetchHandlers) {
            let notificationClasses = [self.fetchHandlers objectForKey:handler];
            if (notificationClasses == nil) continue;

            for (Class notificationClass in notificationClasses) {
                if (![notification isKindOfClass:notificationClass]) continue;
                [handlers addObject:handler];
            }
        }
    }

    return [handlers allObjects];
}

- (void)addFetchHandler:(__weak id<AUTRemoteUserNotificationFetchHandler>)weakFetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    __strong let strongFetchHandler = weakFetchHandler;
    if (strongFetchHandler == nil) return;

    @synchronized (self) {
        var notificationClasses = [self.fetchHandlers objectForKey:strongFetchHandler];
        if (notificationClasses == nil) {
            notificationClasses = [NSSet setWithObject:notificationClass];
        } else {
            notificationClasses = [notificationClasses setByAddingObject:notificationClass];
        }

        [self.fetchHandlers setObject:notificationClasses forKey:strongFetchHandler];
    }
}

- (void)removeFetchHandler:(__weak id<AUTRemoteUserNotificationFetchHandler>)weakFetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    __strong let strongFetchHandler = weakFetchHandler;
    if (strongFetchHandler == nil) return;

    @synchronized (self) {
        NSSet<Class> *notificationClasses = [self.fetchHandlers objectForKey:strongFetchHandler];
        if (notificationClasses == nil) return;

        NSMutableSet<Class> *mutableNotificationClasses = [notificationClasses mutableCopy];
        [mutableNotificationClasses removeObject:notificationClass];
        if (mutableNotificationClasses.count == 0) {
            [self.fetchHandlers removeObjectForKey:strongFetchHandler];
        } else {
            [self.fetchHandlers setObject:[mutableNotificationClasses copy] forKey:strongFetchHandler];
        }
    }
}

#pragma mark - Action Handlers

#pragma mark Public

- (RACDisposable *)registerActionHandler:(id<AUTUserNotificationActionHandler>)actionHandler forNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(actionHandler, notificationClass);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTUserNotification.class]);

    [self addActionHandler:actionHandler forUserNotificationsOfClass:notificationClass];

    @weakify(self, actionHandler);
    return [RACDisposable disposableWithBlock:^{
        @strongifyOr(self, actionHandler) return;
        [self removeActionHandler:actionHandler forUserNotificationsOfClass:notificationClass];
    }];
}

#pragma mark Private

/// For each notification sent over the specified signal, performs an action
/// with each of the registered handlers. Upon completion of all fetches,
/// invokes the responseCompletionHandler property on the sent notification.
- (RACDisposable *)performActionsForRespondedNotifications:(RACSignal<__kindof AUTUserNotification *> *)respondedNotifications {
    NSParameterAssert(respondedNotifications != nil);

    @weakify(self);

    return [[respondedNotifications
        flattenMap:^(__kindof AUTUserNotification *notification) {
            @strongifyOr(self) return [RACSignal empty];

            NSCAssert(notification.response.actionIdentifier != nil, @"Notifications must have an action identifier: %@", notification);
            NSCAssert(notification.responseCompletionHandler != nil, @"Notifications must have an action completion handler: %@", notification);

            return [[self combinedActionHandlerSignalsForNotification:notification]
                doCompleted:^{
                    if ([notification isKindOfClass:AUTRemoteUserNotification.class]) {
                        AUTLogUserNotificationInfo(@"%@ finished performing action '%@' on remote notification: %@", self_weak_, notification.response.actionIdentifier, notification);
                    } else if ([notification isKindOfClass:AUTLocalUserNotification.class]) {
                        AUTLogUserNotificationInfo(@"%@ finished performing action '%@' on local notification: %@", self_weak_, notification.response.actionIdentifier, notification);
                    }
                }];
        }]
        subscribeError:^(NSError *error) {
            let reason = [NSString stringWithFormat:@"%@ -performActionsForNotifications: errored due to programmer error: %@", self_weak_, error];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }];
}

- (RACSignal *)combinedActionHandlerSignalsForNotification:(__kindof AUTUserNotification *)notification {
    AUTAssertNotNil(notification);

    @weakify(self);

    let handlers = [self actionHandlersForNotification:notification];

    // If there were no action handlers for the notification, invoke the action
    // completion handler and complete.
    if (handlers.count == 0) {
        return [RACSignal defer:^{
            AUTLogUserNotificationInfo(@"%@ no handlers for notification <%@: %p>, invoking completion handler", self_weak_, notification.class, notification);

            notification.responseCompletionHandler();
            notification.responseCompletionHandler = nil;

            return [RACSignal empty];
        }];
    }

    // Otherwise, invoke all action handlers and collect the results into an
    // array of RACSignals representing all work that should be done as a result
    // of this action.
    NSArray<RACSignal *> *actionHandlerSignals = [handlers.rac_sequence map:^(id<AUTUserNotificationActionHandler> handler) {
        return [self performActionForNotification:notification withHandler:handler];
    }].array;

    return [[RACSignal merge:actionHandlerSignals]
        // Wait for all action handlers to complete, then invoke the action
        // completion handler.
        doCompleted:^{
            AUTLogUserNotificationInfo(@"%@ all action handlers completed for notification <%@: %p>, invoking completion handler", self_weak_, notification.class, notification);

            notification.responseCompletionHandler();
            notification.responseCompletionHandler = nil;
        }];
}

- (RACSignal *)performActionForNotification:(AUTUserNotification *)notification withHandler:(id<AUTUserNotificationActionHandler>)handler {
    AUTAssertNotNil(notification, handler);

    @weakify(self, handler);

    let performAction = [handler performActionForNotification:notification];
    NSAssert(performAction != nil, @"%@ %@ must return a signal", handler, NSStringFromSelector(@selector(performActionForNotification:)));

    return [[performAction ignoreValues]
        doError:^(NSError *error) {
            let reason = [NSString stringWithFormat:@"%@ %@ -performActionForNotification: errored due to programmer error: %@", self_weak_, handler_weak_, error];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }];
}

- (NSArray<id<AUTUserNotificationActionHandler>> *)actionHandlersForNotification:(AUTUserNotification *)notification {
    AUTAssertNotNil(notification);

    NSMutableSet<id<AUTUserNotificationActionHandler>> *handlers = [NSMutableSet set];

    @synchronized (self) {
        for (id<AUTUserNotificationActionHandler> handler in self.actionHandlers) {
            NSSet<Class> *notificationClasses = [self.actionHandlers objectForKey:handler];
            if (notificationClasses == nil) continue;

            for (Class notificationClass in notificationClasses) {
                if (![notification isKindOfClass:notificationClass]) continue;
                [handlers addObject:handler];
            }
        }
    }

    return [handlers allObjects];
}

- (void)addActionHandler:(__weak id<AUTUserNotificationActionHandler>)weakActionHandler forUserNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    __strong let strongActionHandler = weakActionHandler;
    if (strongActionHandler == nil) return;

    @synchronized (self) {
        var notificationClasses = [self.actionHandlers objectForKey:strongActionHandler];
        if (notificationClasses == nil) {
            notificationClasses = [NSSet setWithObject:notificationClass];
        } else {
            notificationClasses = [notificationClasses setByAddingObject:notificationClass];
        }

        [self.actionHandlers setObject:notificationClasses forKey:strongActionHandler];
    }
}

- (void)removeActionHandler:(__weak id<AUTUserNotificationActionHandler>)weakActionHandler forUserNotificationsOfClass:(Class)notificationClass {
    AUTAssertNotNil(notificationClass);

    __strong id<AUTUserNotificationActionHandler> strongActionHandler = weakActionHandler;
    if (strongActionHandler == nil) return;

    @synchronized (self) {
        let notificationClasses = [self.actionHandlers objectForKey:strongActionHandler];
        if (notificationClasses == nil) return;

        NSMutableSet *mutableNotificationClasses = [notificationClasses mutableCopy];
        [mutableNotificationClasses removeObject:notificationClass];
        if (mutableNotificationClasses.count == 0) {
            [self.actionHandlers removeObjectForKey:strongActionHandler];
        } else {
            [self.actionHandlers setObject:[mutableNotificationClasses copy] forKey:strongActionHandler];
        }
    }
}

#pragma mark - Presented Notifications

- (RACSignal<AUTUserNotification *> *)presentedNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert([notificationClass isSubclassOfClass:AUTUserNotification.class]);

    return [[self.presentedNotifications
        filter:^(AUTUserNotification *notification) {
            return [notification isKindOfClass:notificationClass];
        }]
        setNameWithFormat:@"-presentedNotificationsOfClass: %@", notificationClass];
}

- (NSArray<AUTUserNotificationPresentationOverride> *)presentationOverrides {
    @synchronized (self) {
        return [self->_presentationOverrides copy];
    }
}

- (RACDisposable *)addPresentationOverride:(AUTUserNotificationPresentationOverride)override {
    AUTAssertNotNil(override);

    override = [override copy];

    @synchronized (self) {
        [self->_presentationOverrides addObject:override];
    }

    @weakify(self, override);
    return [RACDisposable disposableWithBlock:^{
        @strongifyOr(self, override) return;
        @synchronized (self) {
            [self->_presentationOverrides removeObject:override];
        }
    }];
}

#pragma mark - AUTUserNotificationsViewModel <UNUserNotificationCenterDelegate>

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    [self.presentationOverrideScheduler schedule:^{
        let userNotification = [AUTUserNotification
            notificationRestoredFromRequest:notification.request
            rootRemoteNotificationClass:self.rootRemoteNotificationClass];

        if (userNotification == nil) {
            AUTLogUserNotificationInfo(@"%@ unable to test notification to override presentation options, could not create AUTUserNotification from %@", self, notification);
            completionHandler(self.defaultPresentationOptions);
            return;
        }

        [self->_presentedNotifications sendNext:userNotification];

        let overrides = self.presentationOverrides;
        if (overrides.count == 0) {
            completionHandler(self.defaultPresentationOptions);
            return;
        }

        NSNumber * _Nullable overrideValue = [[overrides.rac_sequence
            map:^(AUTUserNotificationPresentationOverride test) {
                return test(userNotification);
            }]
            objectPassingTest:^ BOOL (NSNumber * _Nullable overrideValue) {
                return overrideValue != nil;
            }];

        if (overrideValue == nil) {
            completionHandler(self.defaultPresentationOptions);
            return;
        }

        UNNotificationPresentationOptions override = overrideValue.unsignedIntegerValue;
        AUTLogUserNotificationInfo(@"%@ overriding presentation options to %@ for notification %@", self, AUTUNNotificationPresentationOptionsDescription(override), notification);
        completionHandler(override);
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    let notification = [AUTUserNotification
        notificationRestoredFromResponse:response
        rootRemoteNotificationClass:self.rootRemoteNotificationClass
        completionHandler:completionHandler];

    [_respondedNotifications sendNext:notification];
}

@end

NS_ASSUME_NONNULL_END
