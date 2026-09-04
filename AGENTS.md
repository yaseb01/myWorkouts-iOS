# Agents

## Build & Test

- Open `myWorkouts.xcodeproj` in Xcode — no CocoaPods/SPM package files in repo
- Build: `xcodebuild -project myWorkouts.xcodeproj -scheme myWorkouts -configuration Debug build`
- Test: `xcodebuild test -project myWorkouts.xcodeproj -scheme myWorkouts`
- Run on simulator: select scheme in Xcode and press Run (Cmd+R)

## Architecture

- **UI**: SwiftUI, 5-tab navigation (Home, Record, History, Analysis, Settings)
- **Persistence**: SwiftData with 7 models: `Workout`, `TrackPoint`, `SensorSample`, `Goal`, `SportType`, `HeartRateZone`, `UserProfile`
- **Services**: `LocationManager` (GPS), `SensorManager` (BLE HR), `WorkoutRecorder` (state machine), `GPXManager` (import/export)
- **Minimum iOS**: 17
- **Entry point**: `Sources/App/myWorkoutsApp.swift`

## Data Seeding

On first launch, `myWorkoutsApp.seedDefaultDataIfNeeded()` inserts:
- 11 default `SportType` entries (Running, Cycling, etc.)
- 6 default `HeartRateZone` entries (Resting through Maximum)
- One `UserProfile` instance

## Schema Migration

`myWorkoutsApp.setupContainer()` catches schema change errors and deletes the old database (`default.store` / `myWorkouts.store`) before retrying. This is intentional — not a bug.

## Test Target

`myWorkoutsTests/` contains structural and integration tests. Test files have `@MainActor` annotations. All tests import `@testable import myWorkouts`.

## Permissions Required

- Location (always & when-in-use)
- Bluetooth (heart rate sensors)
- Notifications (goal reminders)
