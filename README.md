# App Cloner & Scheduler

A powerful Flutter application that allows users to clone installed apps and schedule them to launch automatically at specific times, even when the main application is closed.

## Key Features

- **App Cloning:** Create a clone of any installed application on your device by copying its APK to external storage.
- **Precise Background Scheduling:** Schedule any app to launch at a specific date and time using `android_alarm_manager_plus`.
- **Conflict Detection:** Prevents scheduling two apps at the exact same time, ensuring reliable launches.
- **Future-Only Validation:** Ensures all schedules are set for a future time to prevent errors.
- **Local Persistence:** Uses **Hive** database for high-performance, local storage of all schedules.
- **Search Functionality:** Easily find any installed app using the real-time search filter.

---

## Screen-by-Screen Breakdown

### 1. Home Screen
The central hub of the application, featuring a tab-based navigation system:
- **All Apps Tab:** Displays a searchable list of all installed applications. 
  - Clicking an app navigates directly to the **New Schedule Screen** with that app pre-selected.
  - A play button icon allows users to open any installed app immediately.
- **Schedule Management Tab:** Replaces the initial creation tab to focus on managing existing schedules.

### 2. New Schedule Screen
Where the magic of scheduling happens:
- **App Selection:** If not pre-selected from the Home Screen, users can search and select an app to schedule.
- **Labeling:** Optional labels can be added to schedules (e.g., "Daily Standup").
- **Date & Time Pickers:** Intuitive pickers to set the exact launch moment.
- **Real-time Validation:**
  - Shows a clear warning if the selected time is in the past.
  - Detects and displays a warning if another app is already scheduled for that exact time.
- **Save/Edit:** Handles both creating new schedules and updating existing ones.

### 3. Schedule Management Screen
A dedicated view for keeping track of all your tasks:
- **Active & Expired Lists:** Displays all schedules with their status (Active or Expired).
- **Visual Status:** Uses green for upcoming schedules and red for those in the past or expired.
- **Edit/Delete:** Quick actions to modify a schedule or remove it entirely with a confirmation dialog.
- **Empty State:** A clean placeholder when no schedules have been created yet.

---

## Technical Stack

- **Framework:** Flutter (Material 3)
- **State Management:** Flutter Riverpod
- **Local Database:** Hive (Hive Flutter)
- **Background Tasks:** Android Alarm Manager Plus
- **System Integration:** Android Intent Plus (for app launching)
- **Device Utilities:** Device Apps (for querying installed apps)

## Getting Started

1. **Permissions:** The app requires `QUERY_ALL_PACKAGES`, `SCHEDULE_EXACT_ALARM`, and storage permissions on Android to function correctly.
2. **Setup:**
   ```bash
   flutter pub get
   flutter run
   ```

---

## Important: Background Reliability (Real Devices)

On many real Android devices (especially those with aggressive battery management like Xiaomi, Samsung, or Huawei), background tasks may be delayed or blocked. To ensure schedules trigger at the exact time:

1. **Exact Alarm Permission:** On Android 12+, you may need to manually allow "Alarms & Reminders" in the app's system settings.
2. **Ignore Battery Optimization:** 
   - Go to **Settings > Apps > App Cloner & Scheduler > Battery**.
   - Set it to **"Unrestricted"** or **"Don't Optimize"**.
3. **Auto-Start:** For some manufacturers, you must enable "Auto-start" in the app info settings to allow the app to launch from a cold state.

---

## Background Architecture

When a schedule is saved:
1. The data is persisted in a **Hive** box.
2. An exact, one-shot alarm is registered with the Android system via `AndroidAlarmManager`.
3. Even if the app is killed or the device is idle, the `AlarmService` will trigger a static callback at the precise time to launch the target package.
