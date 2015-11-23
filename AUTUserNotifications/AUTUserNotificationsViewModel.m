//
//  AUTUserNotificationsViewModel.m
//  Automatic
//
//  Created by Eric Horacek on 9/24/15.
//  Copyright © 2015 Automatic Labs. All rights reserved.
//

@import Mantle;
@import ReactiveCocoa;

#import "UIApplication+AUTUserNotificationHandler.h"
#import "UIApplication+AUTUserNotifier.h"

#import "AUTLog.h"
#import "AUTUserNotifier.h"
#import "AUTUserNotificationHandler.h"
#import "AUTRemoteUserNotificationTokenRegistrar.h"
#import "AUTUserNotificationActionHandler.h"
#import "AUTRemoteUserNotificationFetchHandler.h"

#import "AUTUserNotification_Private.h"
#import "AUTLocalUserNotification_Private.h"
#import "AUTRemoteUserNotification_Private.h"

#import "AUTUserNotificationsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUTUserNotificationsViewModel () {
    RACSubject *_receivedLocalNotifications;
    RACSubject *_receivedRemoteNotifications;
    RACSubject *_receivedSilentRemoteNotifications;
    RACSubject *_actedUponNotifications;

    /// A mutable version of the `fetchHandlers` property.
    ///
    /// This should only be used while synchronized on `self`.
    NSMutableDictionary *_fetchHandlers;

    /// A mutable version of the `actionHandlers` property.
    ///
    /// This should only be used while synchronized on `self`.
    NSMutableDictionary *_actionHandlers;
}

/// A dictionary of [NSValue<id<AUTRemoteUserNotificationFetchHandler>>: Class],
/// with keys of weak NSValue-wrapped references to registered fetch handlers,
/// and values of the notification class that the fetch handler is registered
/// for.
@property (readonly, nonatomic, copy) NSDictionary *fetchHandlers;

/// A dictionary of [NSValue<id<AUTUserNotificationActionHandler>>: Class], with
/// keys of weak NSValue-wrapped references to registered action handlers, and
/// values of the notification class that the action handler is registered for.
@property (readonly, nonatomic, copy) NSDictionary *actionHandlers;

@property (readonly, nonatomic, strong) RACSignal *receivedLocalNotifications;
@property (readonly, nonatomic, strong) RACSignal *receivedRemoteNotifications;
@property (readonly, nonatomic, strong) RACSignal *receivedSilentRemoteNotifications;

/// Sends AUTUserNotifications that have had an action performed upon them.
@property (readonly, nonatomic, strong) RACSignal *actedUponNotifications;

@property (readonly, nonatomic, strong) NSObject<AUTUserNotifier> *notifier;
@property (readonly, nonatomic, strong) NSObject<AUTUserNotificationHandler> *handler;

@property (readonly, nonatomic, strong) Class rootRemoteNotificationClass;

@end

@implementation AUTUserNotificationsViewModel

- (instancetype)init {
    return [self initWithRootRemoteNotificationClass:AUTRemoteUserNotification.class];
}

- (instancetype)initWithRootRemoteNotificationClass:(Class)rootRemoteNotificationClass {
    NSParameterAssert(rootRemoteNotificationClass != Nil);

    id<AUTUserNotificationHandler> handler = UIApplication.sharedApplication.aut_userNotificationHandler;
    NSAssert(handler != nil, @"You must confrom your UIApplicationDelegate to AUTUserNotificationHandler to initialize a AUTUserNotificationsViewModel with it as the notification handler.");

    return [self initWithNotifier:UIApplication.sharedApplication handler:handler rootRemoteNotificationClass:rootRemoteNotificationClass];
}

- (instancetype)initWithNotifier:(id<AUTUserNotifier>)notifier handler:(id<AUTUserNotificationHandler>)handler {
    NSParameterAssert(notifier != nil);
    NSParameterAssert(handler != nil);

    return [self initWithNotifier:notifier handler:handler rootRemoteNotificationClass:AUTRemoteUserNotification.class];
}

- (instancetype)initWithNotifier:(id<AUTUserNotifier>)notifier handler:(id<AUTUserNotificationHandler>)handler rootRemoteNotificationClass:(Class)rootRemoteNotificationClass {
    NSParameterAssert(notifier != nil);
    NSParameterAssert(handler != nil);
    NSParameterAssert(rootRemoteNotificationClass != Nil);
    NSAssert([rootRemoteNotificationClass isSubclassOfClass:AUTRemoteUserNotification.class], @"The rootRemoteNotificationClass must descend from AUTRemoteUserNotification");

    self = [super init];
    if (self == nil) return nil;

    _notifier = notifier;
    _handler = handler;
    _rootRemoteNotificationClass = rootRemoteNotificationClass;
    _fetchHandlers = [NSMutableDictionary dictionary];
    _actionHandlers = [NSMutableDictionary dictionary];

    // Share a subscription to received local notifications.
    _receivedLocalNotifications = [[RACSubject subject] setNameWithFormat:@"-receivedLocalNotifications"];
    [[self createReceivedLocalNotifications] subscribe:_receivedLocalNotifications];

    // Share a subscription to received remote notifications.
    _receivedRemoteNotifications = [[RACSubject subject] setNameWithFormat:@"-receivedRemoteNotifications"];
    [[self createReceivedRemoteNotifications] subscribe:_receivedRemoteNotifications];
    
    // Share a subscription to received silent remote notifications.
    _receivedSilentRemoteNotifications = [[RACSubject subject] setNameWithFormat:@"-receivedSilentRemoteNotifications"];
    [[self createReceivedSilentRemoteNotifications] subscribe:_receivedSilentRemoteNotifications];

    // Perform fetches for all registered handlers as silent notifications are
    // received.
    [self performFetchesForSilentRemoteNotifications:_receivedSilentRemoteNotifications];

    _actedUponNotifications = [[RACSubject subject] setNameWithFormat:@"-actedUponNotifications"];
    [[self createActedUponNotifications] subscribe:_actedUponNotifications];

    // Perform the action of all registered action handlers when notifications
    // are acted upon.
    [self performActionsForNotifications:_actedUponNotifications];

    // Complete subjects when self deallocates.
    [self.rac_willDeallocSignal subscribe:_receivedLocalNotifications];
    [self.rac_willDeallocSignal subscribe:_receivedRemoteNotifications];
    [self.rac_willDeallocSignal subscribe:_receivedSilentRemoteNotifications];
    [self.rac_willDeallocSignal subscribe:_actedUponNotifications];

    _registerSettingsCommand = [self createRegisterSettingsCommand];
    _registerForRemoteNotificationsCommand = [self createRegisterForRemoteNotificationsCommand];

    return self;
}

#pragma mark - Settings Registration

- (RACSignal *)registeredSettings {
    return [[self.handler
        rac_signalForSelector:@selector(application:didRegisterUserNotificationSettings:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^(id _, UIUserNotificationSettings *settings){
            return settings;
        }];
}

- (RACCommand *)createRegisterSettingsCommand {
    @weakify(self);

    return [[RACCommand alloc] initWithSignalBlock:^(UIUserNotificationSettings *settings) {
        NSCAssert(settings != nil, @"-createRegisterSettingsCommand must be executed with desired settings");

        @strongify(self);
        if (self == nil) return [RACSignal empty];

        // If specified settings are equal to existing settings, return
        // immediately.
        UIUserNotificationSettings *currentSettings = self.notifier.currentUserNotificationSettings;
        if (currentSettings != nil && [settings isEqual:currentSettings]) {
            AUTLogUserNotificationRegistrationInfo(@"%@ settings equal to current settings, doing nothing", self);

            return [RACSignal return:currentSettings];
        }

        // Sends the next registered settings. Replayed to prevent races with
        // the below registration method invocation.
        RACSignal *registeredSettings = [[[[self registeredSettings]
            take:1]
            doNext:^(UIUserNotificationSettings *settings) {
                @strongify(self);
                AUTLogUserNotificationRegistrationInfo(@"%@ received registered settings accepted by user: %@", self, settings);
            }]
            replay];

        AUTLogUserNotificationRegistrationInfo(@"%@ registering settings with system: %@", self, settings);
        [self.notifier registerUserNotificationSettings:settings];

        return registeredSettings;
    }];
}

#pragma mark - Remote Notification Registration

- (RACSignal *)registeredRemoteNotificationsDeviceTokens {
    return [[self.handler
        rac_signalForSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^(id _, NSData *deviceToken){
            return deviceToken;
        }];
}

- (RACSignal *)remoteNotificationRegistrationErrors {
    return [[self.handler
        rac_signalForSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^(id _, NSError *error){
            return error;
        }];
}

// Upon subscription, creates a device token and registers it with APNS. Sends
// the resulting device token as an NSData instance upon success or errors
// otherwise.
- (RACSignal *)registerDeviceTokenWithSystem {
    return [RACSignal defer:^{
        // Sends the registered token. Replayed to prevent races.
        RACSignal *registeredToken = [[[self registeredRemoteNotificationsDeviceTokens]
            doNext:^(NSData *token) {
                AUTLogUserNotificationRegistrationInfo(@"%@ received device token from system %@", self, token);
            }]
            replay];

        // Errors if an error occurs during registration. Replayed to prevent
        // races with registration.
        RACSignal *registrationError = [[[[self remoteNotificationRegistrationErrors]
            flattenMap:^(NSError *error) {
                return [RACSignal error:error];
            }]
            doError:^(NSError *error) {
                AUTLogUserNotificationRegistrationInfo(@"%@ received error requesting device token from system: %@", self, error);
            }]
            replay];

        AUTLogUserNotificationRegistrationInfo(@"%@ requesting device token from system...", self);
        [self.notifier registerForRemoteNotifications];

        // Sends the token if successful, errors otherwise.
        return [[RACSignal merge:@[ registeredToken, registrationError ]]
            // Complete immediately if a token is sent.
            take:1];
    }];
}

- (RACCommand *)createRegisterForRemoteNotificationsCommand {
    @weakify(self);

    // Enable only when a token registrar is set.
    RACSignal *enabled = [RACObserve(self, tokenRegistrar) map:^(id<AUTRemoteUserNotificationTokenRegistrar> tokenRegistrar) {
        return tokenRegistrar != nil ? @YES : @NO;
    }];

    return [[RACCommand alloc] initWithEnabled:enabled signalBlock:^(id _) {
        @strongify(self);
        if (self == nil) return [RACSignal empty];

        RACSignal *registerDeviceTokenWithSystem = [self registerDeviceTokenWithSystem];

        return [registerDeviceTokenWithSystem flattenMap:^(NSData *deviceToken) {
            @strongify(self);
            if (self == nil) return [RACSignal empty];

            return [[[self.tokenRegistrar registerDeviceToken:deviceToken]
                initially:^{
                    @strongify(self);
                    AUTLogUserNotificationRegistrationInfo(@"%@ registering token %@ with registrar %@...", self, deviceToken, self.tokenRegistrar);
                }]
                doCompleted:^{
                    @strongify(self);
                    AUTLogUserNotificationRegistrationInfo(@"%@ successfully registered token %@ with registrar %@...", self, deviceToken, self.tokenRegistrar);
                }];
        }];
    }];
}

#pragma mark - Notification Reception

- (nullable AUTRemoteUserNotification *)remoteNotificationFromJSONDictionary:(NSDictionary *)JSONDictionary {
    NSParameterAssert(JSONDictionary != nil);

    Class remoteNotificationClass = [self.rootRemoteNotificationClass classForParsingJSONDictionary:JSONDictionary];

    NSError *error;
    AUTRemoteUserNotification *notification = [MTLJSONAdapter modelOfClass:remoteNotificationClass fromJSONDictionary:JSONDictionary error:&error];
    if (notification == nil) {
        AUTLogRemoteUserNotificationError(@"Unable to generate AUTRemoteUserNotification from JSON: %@, error: %@", JSONDictionary, error);
    }

    return notification;
}

- (RACSignal *)createReceivedLocalNotifications {
    @weakify(self);

    return [[[[self.handler
        rac_signalForSelector:@selector(application:didReceiveLocalNotification:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^(id _, UILocalNotification *systemNotification){
            return [AUTLocalUserNotification notificationFromSystemNotification:systemNotification];
        }]
        // Ignore notifications that do not contain an encoded local user
        // notification in their user info.
        ignore:nil]
        doNext:^(AUTLocalUserNotification *notification) {
            @strongify(self);

            AUTLogLocalUserNotificationInfo(@"%@ received local notification: %@", self, notification);
        }];
}

- (RACSignal *)createReceivedRemoteNotifications {
    @weakify(self);

    return [[[[self.handler
        rac_signalForSelector:@selector(application:didReceiveRemoteNotification:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^ AUTRemoteUserNotification * (id _, NSDictionary *JSONDictionary){
            @strongify(self);
            if (self == nil) return nil;

            return [self remoteNotificationFromJSONDictionary:JSONDictionary];
        }]
        // Ignore notifications that do not validly parse to a remote
        // notification.
        ignore:nil]
        doNext:^(AUTRemoteUserNotification *notification) {
            @strongify(self);
            AUTLogRemoteUserNotificationInfo(@"%@ received remote notification: %@", self, notification);
        }];
}

- (RACSignal *)receivedNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert([notificationClass isSubclassOfClass:AUTUserNotification.class]);

    RACSignal *localNotifications = self.receivedLocalNotifications;

    // Do not send remote notifications that are triggering a background fetch,
    // as they are handled in a way that can indicate when the fetch completes.
    RACSignal *nonSilentRemoteNotifications = [self.receivedRemoteNotifications filter:^ BOOL (AUTRemoteUserNotification *notification) {
        return !notification.isSilent;
    }];

    return [[[RACSignal
        merge:@[ localNotifications, nonSilentRemoteNotifications ]]
        filter:^(AUTLocalUserNotification *notification) {
            return [notification isKindOfClass:notificationClass];
        }]
        setNameWithFormat:@"-receivedNotificationsOfClass: %@", notificationClass];
}

#pragma mark - Silent Remote Notifications

#pragma mark Public

- (RACDisposable *)registerFetchHandler:(id<AUTRemoteUserNotificationFetchHandler>)fetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert(fetchHandler != nil);
    NSParameterAssert(notificationClass != nil);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTRemoteUserNotification.class]);

    [self addFetchHandler:fetchHandler forRemoteUserNotificationsOfClass:notificationClass];

    @weakify(fetchHandler);
    return [RACDisposable disposableWithBlock:^{
        @strongify(fetchHandler);

        [self removeFetchHandler:fetchHandler];
    }];
}

#pragma mark Private

/// Creates a signal that sends silent AUTRemoteUserNotification instances as
/// they are received.
///
/// Populates the fetchCompletionHandler property on the sent notification, for
/// execution when all fetch handlers have performed their fetch.
- (RACSignal *)createReceivedSilentRemoteNotifications {
    @weakify(self);

    return [[[self.handler
        rac_signalForSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^ AUTRemoteUserNotification * (id _, NSDictionary *JSONDictionary, void (^fetchCompletionHandler)(UIBackgroundFetchResult)){
            @strongify(self);
            if (self == nil) return nil;

            AUTRemoteUserNotification *notification = [self remoteNotificationFromJSONDictionary:JSONDictionary];
            notification.systemFetchCompletionHandler = fetchCompletionHandler;
            return notification;
        }]
        // Ignore notifications that do not validly parse to a remote
        // notification.
        ignore:nil];
}

/// For each sent silent remote notification sent over the specified signal,
/// performs a fetch for each of the registered fetch handlers with the
/// notification. Upon completion of all fetches, invokes the
/// fetchCompletionHandler property on the sent notification with the worst
/// of the fetch results.
- (RACDisposable *)performFetchesForSilentRemoteNotifications:(RACSignal *)receivedSilentRemoteNotifications {
    NSParameterAssert(receivedSilentRemoteNotifications != nil);

    @weakify(self);

    return [[receivedSilentRemoteNotifications
        flattenMap:^(AUTRemoteUserNotification *notification) {
            @strongify(self);
            if (self == nil) return [RACSignal empty];

            NSCAssert(notification.systemFetchCompletionHandler != nil, @"Silent remote notifications must have a fetch completion handler: %@", notification);

            return [[[self combinedFetchHandlerSignalsForSilentRemoteNotification:notification]
                initially:^{
                    @strongify(self);
                    AUTLogRemoteUserNotificationInfo(@"%@ performing fetch for silent remote notification: %@", self, notification);
                }]
                doCompleted:^{
                    @strongify(self);
                    AUTLogRemoteUserNotificationInfo(@"%@ finished performing fetch for silent remote notification: %@", self, notification);
                }];
        }]
        subscribeError:^(NSError *error) {
            @strongify(self);

            NSString *reason = [NSString stringWithFormat:@"%@ -performFetchesForSilentRemoteNotifications errored due to programmer error: %@", self, error];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }];
}

- (RACSignal *)combinedFetchHandlerSignalsForSilentRemoteNotification:(AUTRemoteUserNotification *)notification {
    NSParameterAssert(notification != nil);

    NSArray <id<AUTRemoteUserNotificationFetchHandler>> *handlers = [self fetchHandlersForSilentRemoteNotification:notification];

    // If there were no fetch handlers for the notification, invoke the fetch
    // completion handler with NoData and complete.
    if (handlers.count == 0) {
        return [RACSignal defer:^{
            notification.systemFetchCompletionHandler(UIBackgroundFetchResultNoData);
            notification.systemFetchCompletionHandler = nil;

            return [RACSignal empty];
        }];
    }

    // Otherwise, invoke all fetch handlers and collect results into an array of
    // RACSignals representing all work that should be done as a result of this
    // notification.
    NSArray *fetchHandlerSignals = [handlers.rac_sequence map:^(id<AUTRemoteUserNotificationFetchHandler> handler) {
        return [self performFetchForNotification:notification withHandler:handler];
    }].array;

    return [[[[RACSignal merge:fetchHandlerSignals]
        // Wait for all fetch handlers to complete and send their statuses.
        collect]
        // Find the "worst" returned status of all handlers.
        map:^(NSArray *backgroundRefreshResults) {
            // Sorts the statuses in the order of NewData, NoData, Failed.
            NSArray *sortedStatues = [backgroundRefreshResults sortedArrayUsingSelector: @selector(compare:)];

            // The last status is the "worst", so send it.
            return sortedStatues.lastObject;
        }]
        // Invoke the system completion handler with the "worst" status
        // resulting from all registered handlers.
        doNext:^(NSNumber *worstStatus) {
            notification.systemFetchCompletionHandler(worstStatus.unsignedIntegerValue);
            notification.systemFetchCompletionHandler = nil;
        }];
}

- (RACSignal *)performFetchForNotification:(AUTRemoteUserNotification *)notification withHandler:(id<AUTRemoteUserNotificationFetchHandler>)handler {
    NSParameterAssert(notification != nil);
    NSParameterAssert(handler != nil);

    __block BOOL didSendValidValue = NO;
    __weak id<AUTRemoteUserNotificationFetchHandler> weakHandler = handler;

    return [[[[handler performFetchForNotification:notification]
        doNext:^(NSNumber *refreshResult) {
            NSCAssert(!didSendValidValue, @"%@ -performFetchForNotification: %@ must only send one next value, instead received: %@", weakHandler, notification, refreshResult);
            NSCAssert([refreshResult isKindOfClass:NSNumber.class], @"%@ -performFetchForNotification: %@ must send an NSNumber, instead received: %@", weakHandler, notification, refreshResult);

            switch ((UIBackgroundFetchResult)refreshResult.unsignedIntegerValue) {
            case UIBackgroundFetchResultNewData:
            case UIBackgroundFetchResultNoData:
            case UIBackgroundFetchResultFailed:
                didSendValidValue = YES;
                return;
            }

            NSString *reason = [NSString stringWithFormat:@"%@ -performFetchForNotification: %@ sent an invalid refresh result: %@", weakHandler, notification, refreshResult];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }]
        doError:^(NSError *error) {
            NSCAssert(error, @"%@ -performFetchForNotification: %@ errored: %@. All errors must be caught.", weakHandler, notification, error);
        }]
        doCompleted:^{
            NSCAssert(didSendValidValue, @"%@ -performFetchForNotification: %@ must send a UIBackgroundFetchResult before completing", weakHandler, notification);
        }];
}

#pragma mark - Fetch Handlers Dictionary

- (NSArray <id<AUTRemoteUserNotificationFetchHandler>> *)fetchHandlersForSilentRemoteNotification:(AUTRemoteUserNotification *)notification {
    NSParameterAssert(notification != nil);

    return [[[[self.fetchHandlers
        keysOfEntriesPassingTest:^(NSValue *handler, Class notificationClass, BOOL *_) {
            return [notification isKindOfClass:notificationClass];
        }]
        rac_sequence]
        // Unwrap the object from the nonretained value.
        map:^(NSValue *fetchHandler) {
            return fetchHandler.nonretainedObjectValue;
        }]
        array];
}

- (NSDictionary *)fetchHandlers {
    @synchronized(self) {
        return [_fetchHandlers copy];
    }
}

- (void)addFetchHandler:(__weak id<AUTRemoteUserNotificationFetchHandler>)fetchHandler forRemoteUserNotificationsOfClass:(Class)notificationClass {
    __strong id<AUTRemoteUserNotificationFetchHandler> strongFetchHandler = fetchHandler;
    if (strongFetchHandler == nil) return;

    @synchronized (self) {
        _fetchHandlers[[NSValue valueWithNonretainedObject:strongFetchHandler]] = notificationClass;
    }
}

- (void)removeFetchHandler:(__weak id<AUTRemoteUserNotificationFetchHandler>)fetchHandler {
    __strong id<AUTRemoteUserNotificationFetchHandler> strongFetchHandler = fetchHandler;
    if (strongFetchHandler == nil) return;

    @synchronized (self) {
        [_fetchHandlers removeObjectForKey:[NSValue valueWithNonretainedObject:fetchHandler]];
    }
}

#pragma mark - Action Handler Management

#pragma mark Public

- (RACDisposable *)registerActionHandler:(id<AUTUserNotificationActionHandler>)actionHandler forNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert(actionHandler != nil);
    NSParameterAssert(notificationClass != nil);
    NSParameterAssert([notificationClass isSubclassOfClass:AUTUserNotification.class]);

    [self addActionHandler:actionHandler forUserNotificationsOfClass:notificationClass];

    @weakify(actionHandler);
    return [RACDisposable disposableWithBlock:^{
        @strongify(actionHandler);

        [self removeActionHandler:actionHandler];
    }];
}

#pragma mark Private

/// Creates a signal that sends AUTUserNotifications that have actions performed
/// on them.
///
/// Populates the actionIdentifier and systemActionCompletionHandler properties on the
/// sent notifications.
- (RACSignal *)createActedUponNotifications {
    @weakify(self);

    RACSignal *localActions = [[[[self.handler
        rac_signalForSelector:@selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^ AUTLocalUserNotification * (id _, NSString *actionIdentifier, UILocalNotification *systemNotification, void (^completionHandler)()){
            @strongify(self);
            if (self == nil) return nil;

            AUTLocalUserNotification *notification = [AUTLocalUserNotification notificationFromSystemNotification:systemNotification];
            notification.actionIdentifier = actionIdentifier;
            notification.systemActionCompletionHandler = completionHandler;
            return notification;
        }]
        // Ignore notifications that do not contain an encoded local user
        // notification in their user info.
        ignore:nil]
        doNext:^(AUTLocalUserNotification *notification) {
            @strongify(self);
            AUTLogLocalUserNotificationInfo(@"%@ performing action '%@' on local notification: %@ ", self, notification.actionIdentifier, notification);
        }];

    RACSignal *remoteActions = [[[[self.handler
        rac_signalForSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:) fromProtocol:@protocol(AUTUserNotificationHandler)]
        reduceEach:^ AUTRemoteUserNotification * (id _, NSString *actionIdentifier, NSDictionary *JSONDictionary, void (^completionHandler)()){
            @strongify(self);
            if (self == nil) return nil;

            AUTRemoteUserNotification *notification = [self remoteNotificationFromJSONDictionary:JSONDictionary];
            notification.systemActionCompletionHandler = completionHandler;
            notification.actionIdentifier = actionIdentifier;
            return notification;
        }]
        // Ignore notifications that do not validly parse to a remote
        // notification.
        ignore:nil]
        doNext:^(AUTRemoteUserNotification *notification) {
            @strongify(self);
            AUTLogRemoteUserNotificationInfo(@"%@ performing action '%@' on remote notification: %@ ", self, notification.actionIdentifier, notification);
        }];

    return [RACSignal merge:@[ localActions, remoteActions ]];
}

/// For each sent acted upon notification sent over the specified signal,
/// performs a fetch for each of the registered fetch handlers with the
/// notification. Upon completion of all fetches, invokes the
/// fetchCompletionHandler property on the sent notification with the worst
/// of the fetch results.
- (RACDisposable *)performActionsForNotifications:(RACSignal *)actedUponNotifications {
    NSParameterAssert(actedUponNotifications != nil);

    @weakify(self);

    return [[actedUponNotifications
        flattenMap:^(AUTUserNotification *notification) {
            @strongify(self);
            if (self == nil) return [RACSignal empty];

            NSCAssert(notification.actionIdentifier != nil, @"Acted upon notifications must have an action identifier: %@", notification);
            NSCAssert(notification.systemActionCompletionHandler != nil, @"Acted upon notifications must have an action completion handler: %@", notification);

            return [[self combinedActionHandlerSignalsForNotification:notification]
                doCompleted:^{
                    @strongify(self);
                    if ([notification isKindOfClass:AUTRemoteUserNotification.class]) {
                        AUTLogRemoteUserNotificationInfo(@"%@ finished performing action '%@' on remote notification: %@", self, notification.actionIdentifier, notification);
                    } else if ([notification isKindOfClass:AUTLocalUserNotification.class]) {
                        AUTLogLocalUserNotificationInfo(@"%@ finished performing action '%@' on local notification: %@", self, notification.actionIdentifier, notification);
                    }
                }];
        }]
        subscribeError:^(NSError *error) {
            @strongify(self);

            NSString *reason = [NSString stringWithFormat:@"%@ -performActionsForActedUponNotifications errored due to programmer error: %@", self, error];
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
        }];
}

- (RACSignal *)combinedActionHandlerSignalsForNotification:(AUTUserNotification *)notification {
    NSParameterAssert(notification != nil);

    NSArray <id<AUTUserNotificationActionHandler>> *handlers = [self actionHandlersForNotification:notification];

    // If there were no action handlers for the notification, invoke the action
    // completion handler and complete.
    if (handlers.count == 0) {
        return [RACSignal defer:^{
            notification.systemActionCompletionHandler();
            notification.systemActionCompletionHandler = nil;

            return [RACSignal empty];
        }];
    }

    // Otherwise, invoke all action handlers and collect the results into an
    // array of RACSignals representing all work that should be done as a result
    // of this action.
    NSArray *actionHandlerSignals = [handlers.rac_sequence map:^(id<AUTUserNotificationActionHandler> handler) {
        return [self performActionForNotification:notification withHandler:handler];
    }].array;

    return [[RACSignal merge:actionHandlerSignals]
        // Wait for all action handlers to complete, then invoke the action
        // completion handler.
        doCompleted:^{
            notification.systemActionCompletionHandler();
            notification.systemActionCompletionHandler = nil;
        }];
}

- (RACSignal *)performActionForNotification:(AUTUserNotification *)notification withHandler:(id<AUTUserNotificationActionHandler>)handler {
    NSParameterAssert(notification != nil);
    NSParameterAssert(handler != nil);

    __weak id<AUTUserNotificationActionHandler> weakHandler = handler;

    return [[[handler performActionForNotification:notification]
        ignoreValues]
        doError:^(NSError *error) {
            NSCAssert(error, @"%@ -performActionForNotification: %@ errored: %@. All errors must be caught.", weakHandler, notification, error);
        }];
}

#pragma mark - Action Handlers Dictionary

- (NSArray <id<AUTUserNotificationActionHandler>> *)actionHandlersForNotification:(AUTUserNotification *)notification {
    NSParameterAssert(notification != nil);

    return [[[[self.actionHandlers
        keysOfEntriesPassingTest:^(NSValue *handler, Class notificationClass, BOOL *_) {
            return [notification isKindOfClass:notificationClass];
        }]
        rac_sequence]
        // Unwrap the object from the nonretained value.
        map:^(NSValue *actionHandler) {
            return actionHandler.nonretainedObjectValue;
        }]
        array];
}

- (NSDictionary *)actionHandlers {
    @synchronized(self) {
        return [_actionHandlers copy];
    }
}

- (void)addActionHandler:(__weak id<AUTUserNotificationActionHandler>)actionHandler forUserNotificationsOfClass:(Class)notificationClass {
    __strong id<AUTUserNotificationActionHandler> strongActionHandler = actionHandler;
    if (strongActionHandler == nil) return;

    @synchronized (self) {
        _actionHandlers[[NSValue valueWithNonretainedObject:strongActionHandler]] = notificationClass;
    }
}

- (void)removeActionHandler:(__weak id<AUTUserNotificationActionHandler>)actionHandler {
    __strong id<AUTUserNotificationActionHandler> strongActionHandler = actionHandler;
    if (strongActionHandler == nil) return;

    @synchronized (self) {
        [_actionHandlers removeObjectForKey:[NSValue valueWithNonretainedObject:actionHandler]];
    }
}

#pragma mark - Local Notification Management

- (RACSignal *)scheduledLocalNotifications {
    return [[RACSignal
        defer:^{
            return [self.notifier.scheduledLocalNotifications.rac_sequence signalWithScheduler:RACScheduler.immediateScheduler];
        }]
        map:^(UILocalNotification *notification) {
            return [AUTLocalUserNotification notificationFromSystemNotification:notification];
        }];
}

- (RACSignal *)scheduledLocalNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert([notificationClass isSubclassOfClass:AUTLocalUserNotification.class]);

    return [[self scheduledLocalNotifications]
        filter:^(AUTLocalUserNotification *notification) {
            return [notification isKindOfClass:notificationClass];
        }];
}

- (RACSignal *)scheduleLocalNotification:(AUTLocalUserNotification *)notification {
    NSParameterAssert(notification != nil);

    return [RACSignal defer:^{
        UILocalNotification *systemNotification = [notification createSystemNotification];
        if (systemNotification == nil) return [RACSignal empty];

        AUTLogLocalUserNotificationInfo(@"%@ scheduling local notification: %@ ", self, notification);

        if (systemNotification.fireDate != nil) {
            [self.notifier scheduleLocalNotification:systemNotification];
        } else {
            [self.notifier presentLocalNotificationNow:systemNotification];
        }

        return [RACSignal empty];
    }];
}

- (RACSignal *)cancelLocalNotificationsOfClass:(Class)notificationClass {
    NSParameterAssert([notificationClass isSubclassOfClass:AUTLocalUserNotification.class]);

    return [[[[self scheduledLocalNotificationsOfClass:notificationClass]
        doNext:^(AUTLocalUserNotification *notification) {
            AUTLogLocalUserNotificationInfo(@"%@ canceling local notification: %@ ", self, notification);
        }]
        doNext:^(AUTLocalUserNotification *notification) {
            [self.notifier cancelLocalNotification:notification.systemNotification];
        }]
        ignoreValues];
}

- (RACSignal *)cancelLocalNotificationsOfClass:(Class)notificationClass passingTest:(BOOL (^)(__kindof AUTLocalUserNotification *notification))testBlock {
    NSParameterAssert([notificationClass isSubclassOfClass:AUTLocalUserNotification.class]);

    return [[[[[self scheduledLocalNotificationsOfClass:notificationClass]
        filter:testBlock]
        doNext:^(AUTLocalUserNotification *notification) {
            AUTLogLocalUserNotificationInfo(@"%@ canceling local notification: %@ ", self, notification);
        }]
        doNext:^(AUTLocalUserNotification *notification) {
            [self.notifier cancelLocalNotification:notification.systemNotification];
        }]
        ignoreValues];
}

@end

NS_ASSUME_NONNULL_END
