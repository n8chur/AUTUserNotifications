# AUTUserNotifications

Handle your local and remote notifications using ReactiveCocoa.

## Getting Started:

- Conform your `UIApplicationDelegate` to the `AUTUserNotificationHandler` protocol.

- Create a class to represent each of your notifications.

```swift
@objc class TimerLocalNotification: AUTLocalUserNotification {
    var timer: MyTimer?

    // Configure notifications
    override func createSystemNotification() -> UILocalNotification? {
        guard let notification = super.createSystemNotification() else { return nil }
        guard let timer = timer else { return nil }
        
        notification.alertBody = "Your timer expired!"
        notification.fireDate = timer.expirationDate
        
        return notification
    }
    
    // Implement actions for your notifications
    override class func systemActionsForContext(context: UIUserNotificationActionContext) -> [UIUserNotificationAction]? {
        let action = UIMutableUserNotificationAction()

        action.identifier = "snooze"
        action.title = "Snooze"
        action.activationMode = .Background

        return [action]
    }
}
```

### Register notification settings

```swift
let viewModel = AUTUserNotificationsViewModel()

let settings = UIUserNotificationSettings.aut_synthesizedSettingsForTypes([.Alert, .Badge, .Sound])
viewModel.registerSettingsCommand.execute(settings)
```

### Schedule notifications

```swift
let viewModel = AUTUserNotificationsViewModel()

let didCreateTimer: RACSignal = ...

timerCreatedSignal
    .flattenMap { timer in
        let notification = TimerLocalNotification()
        notification.timer = timer

        return viewModel.scheduleLocalNotification(notification)
    }
    .subscribeCompleted {}
```

### Subscribe to notifications

```swift
let viewModel = AUTUserNotificationsViewModel()

viewModel.receivedNotificationsOfClass(AUTDeveloperLocalNotification.self).subscribeNext { notification in
    guard let notification = notification as? TimerLocalNotification else { return }
    
    // Show the timer
}
```

### Receive action callbacks

```swift
let viewModel = AUTUserNotificationsViewModel()

viewModel.registerActionHandler(self, forNotificationsOfClass: TimerLocalNotification.self)

func performActionForNotification(notification: AUTUserNotification) -> RACSignal {
    guard let notification = notification as? TimerLocalNotification else { return RACSignal.empty() }
        
    // Snooze the timer   
}
```
