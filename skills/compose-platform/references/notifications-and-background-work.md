# Notifications and Background Work

Load when: adding notifications, reminders, or work that must run after leaving a screen.

## Choose

- Does the user need a visible notification?
  - Yes: request Android 13+ `POST_NOTIFICATIONS` at runtime or iOS `UNUserNotificationCenter` authorization at the point of need. If denied, keep the feature usable without alerts and do not nag. *Prevents:* a blocked feature or repeated permission prompts. https://developer.android.com/develop/ui/views/notifications/notification-permission https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
  - No: do not request notification permission. *Prevents:* a prompt unrelated to the feature.
- Is this a user-visible reminder at a set time?
  - Yes: on Android use WorkManager or an alarm (exact only when required; check exact-alarm permission). On iOS schedule a local `UNNotificationRequest` with a `UNCalendarNotificationTrigger` or `UNTimeIntervalNotificationTrigger` and the entity id as its identifier; no background task is needed. *Prevents:* reminders depending on a background task that may run late. https://developer.android.com/develop/background-work/services/alarms/schedule https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger
  - No: for persistent, deferrable Android work use WorkManager; for eligible iOS background processing use BGTaskScheduler. *Prevents:* process death dropping required work. https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work https://developer.apple.com/documentation/backgroundtasks
- Not covered here → use judgement and state the assumption.

## Ownership and lifecycle

Define a `commonMain` scheduling interface taking entity ids; bind platform implementations in DI. *Prevents:* OS APIs leaking into shared code.

Schedule by entity id. On change, replace its pending work; on delete, cancel it. *Prevents:* duplicate or orphaned reminders.

WorkManager persists Android work across process death and reboot; use unique work named from the entity id. Exact alarms need platform permission and are cleared on reboot; reschedule after boot. https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work https://developer.android.com/develop/background-work/services/alarms/schedule

On iOS, schedule or cancel local requests by entity id. `BGTaskScheduler` does not promise exact timing. https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications https://developer.apple.com/documentation/backgroundtasks

On denial, save intent, show alerts are off, and offer settings access. Do not loop prompts. *Prevents:* an unusable reminder feature.
