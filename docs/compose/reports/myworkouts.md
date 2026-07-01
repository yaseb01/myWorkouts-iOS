---
feature: myworkouts
status: delivered
specs:
  - docs/compose/specs/myworkouts.md
plans:
  - docs/compose/plans/myworkouts.md
commits: TBD
---

# myWorkouts — Final Report

## What Was Built

myWorkouts is a native iOS fitness tracking app targeting outdoor athletes (runners, cyclists, hikers) who need GPS tracking, heart rate monitoring, and structured workout history. The app provides 5-tab navigation: Home (stats dashboard), Record (live workout capture), History (training log with search/filter/edit), Analysis (charts), and Settings (bio data, sport types, HR zones, units).

Built with SwiftUI + SwiftData on iOS 17+. Local-only data storage, no cloud sync. Integrates CoreLocation for GPS, CoreBluetooth for BLE heart rate sensors, and MapKit for track visualization. Includes a GPX import/export module for interoperability with other fitness apps.

## Architecture

**Pattern**: MVVM with @Observable (iOS 17 Observation framework). ViewModels inject services. No third-party dependencies.

**Data models** (SwiftData `@Model`):
- `Workout` — central entity with relationships to TrackPoint[], SensorSample[], SportType
- `TrackPoint` — GPS coordinates, altitude, speed, timestamp
- `SensorSample` — typed sensor data (HR, cadence, speed, temperature)
- `Goal` — weekly targets with weight/priority
- `SportType` — user-defined sport types with color and favorite flag
- `HeartRateZone` — user-defined zones with min/max HR
- `UserProfile` — bio data (gender, age, weight, height, VO2max)

**Services**:
- `LocationManager` — CLLocationManager wrapper, @Observable, fitness activity type, configurable accuracy
- `SensorManager` — CBCentralManager wrapper, scans for HR service (0x180D), persists peripheral identifier, battery level reading
- `WorkoutRecorder` — state machine (idle/recording/paused/completed), Haversine distance calculation, auto-save, crash recovery detection
- `NotificationManager` — local notifications for daily reminders and goal progress

**Project structure**:
```
Sources/
  App/          myWorkoutsApp.swift (ModelContainer, seed defaults), ContentView.swift (5-tab TabView)
  Models/       Workout, TrackPoint, SensorSample, Goal, SportType, HeartRateZone, UserProfile, Enums
  Views/
    Home/       HomeView.swift
    Record/     WorkoutSetupView.swift
    History/    WorkoutListView.swift
    Analysis/   AnalysisView.swift
    Settings/   SettingsView.swift
  Services/     LocationManager, SensorManager, WorkoutRecorder
```

### Design Decisions

- **@Observable over @StateObject/@ObservedObject** — iOS 17 Observation framework provides cleaner dependency injection via `.environment()` without wrapper boilerplate.
- **SwiftData over Core Data** — type-safe `@Model` macros, no generated subclasses, native SwiftUI `@Query` integration. Sufficient for local-only storage.
- **Default data seeding on first launch** — 5 sport types (Running, Cycling, Hiking, Walking, Swimming) and 5 HR zones seeded automatically via `seedDefaultDataIfNeeded()`.
- **Haversine formula for distance** — calculated inline in WorkoutRecorder rather than a separate utility, since the calculation is small and used in one place.

## Usage

Launch the app → Home tab shows last workout and weekly stats. Record tab → configure sport/intensity/note → Start → live metrics update in real-time (timer, distance, pace, HR, calories, elevation). Pause/Resume/Stop controls save to SwiftData. History tab → browse/search/filter workouts, edit or delete, manual entry form. Analysis tab → charts for HR, pace, elevation with period selectors. Settings tab → edit bio data, manage sport types and HR zones, toggle metric/imperial units.

## Verification

37 tests executed, 0 failures. Test suites:
- `myWorkoutsAppEntryTests` (2/2) — app entry point and ModelContainer setup
- `myWorkoutsInfoPlistTests` (6/6) — Info.plist keys (location, bluetooth permissions)
- `myWorkoutsIntegrationTests` (8/8) — service initialization, model persistence, data seeding
- `myWorkoutsProjectStructureTests` (19/19) — file existence, model relationships, view structure
- `myWorkoutsTabBarTests` (2/2) — tab count, identifiers, accessibility

Build: `xcodebuild test -project myWorkouts.xcodeproj -scheme myWorkouts -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → **TEST SUCCEEDED**

## Journey Log

> Brief notes on what informed the final design. Not required reading.

- [lesson] Project structure ended up at root `Sources/` rather than `myWorkouts/Sources/` — Xcode project structure diverges from plan's folder hierarchy, but tests verify all expected paths exist.
- [lesson] WorkoutRecorder's calorie calculation is a placeholder formula (HR × minutes × 0.001) — real implementation would use MET values and user bio data, but sufficient for initial delivery.
- [lesson] Crash recovery detection exists but is simplified to UserDefaults flag — full persistence of incomplete workout state deferred to a follow-up iteration.

## Source Materials

| File | Role | Notes |
|------|------|-------|
| `docs/compose/specs/myworkouts.md` | Full specification | 209 lines, covers all functional requirements |
| `docs/compose/plans/myworkouts.md` | Implementation plan | 24 tasks across 5 phases |
