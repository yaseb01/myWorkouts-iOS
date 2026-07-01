# Implementation Plan: myWorkouts iOS App

> [!NOTE]
> This document may not reflect the current implementation.
> See the final report for up-to-date state:
> [Final Report](../reports/myworkouts.md)

## Phase 1: Project Scaffold + Data Models + Settings

### T1: Xcode Project Scaffold
Create the Xcode project structure with proper targets, Info.plist, and entitlements.
- Create Xcode project (myWorkouts.xcodeproj) targeting iOS 17
- Info.plist with required keys: NSLocationWhenInUseUsageDescription, NSLocationAlwaysAndWhenInUseUsageDescription, NSBluetoothAlwaysUsageDescription, NSBluetoothPeripheralUsageDescription
- App entitlements: background modes (location, bluetooth-central)
- Folder structure: Sources/App, Sources/Models, Sources/Views, Sources/ViewModels, Sources/Services, Sources/GPX, Sources/Utilities
- App entry point with SwiftData ModelContainer setup
**Acceptance**: Project builds and runs on simulator with empty tab bar (5 tabs)
**Files**: `myWorkouts.xcodeproj/`, `Sources/App/myWorkoutsApp.swift`, `Sources/App/ContentView.swift`
**dependsOn**: (none)

### T2: Core Data Models
Implement all SwiftData @Model classes for the persistence layer.
- Workout model with relationships to TrackPoint, SensorSample, SportType
- TrackPoint model (lat, lon, altitude, accuracy, speed, course, timestamp)
- SensorSample model (timestamp, type, value, unit)
- Goal model (type, weeklyTarget, unit, weight, isActive)
- SportType model (name, abbreviation, color, isFavorite)
- HeartRateZone model (name, abbreviation, min/max HR, zone number)
- UserProfile model (gender, birthDate, weight, height, vo2max)
- Enum types: IntensityLevel, SensorType, GoalType, Gender
**Acceptance**: All models compile with correct SwiftData macros and relationships; ModelContainer registers all models
**Files**: `Sources/Models/Workout.swift`, `Sources/Models/TrackPoint.swift`, `Sources/Models/SensorSample.swift`, `Sources/Models/Goal.swift`, `Sources/Models/SportType.swift`, `Sources/Models/HeartRateZone.swift`, `Sources/Models/UserProfile.swift`, `Sources/Models/Enums.swift`
**dependsOn**: T1

### T3: Settings Tab - Bio Data & Units
Build the Settings tab with user profile editing and unit preferences.
- UserProfileViewModel (@Observable) for loading/saving bio data
- SettingsView with sections: Bio Data, Units, About
- Bio data form: gender picker, birth date, weight, height, VO2max
- Unit toggle: metric (km, kg, °C) vs imperial (mi, lb, °F)
- Store unit preference in UserDefaults or as part of UserProfile
**Acceptance**: User can enter bio data and toggle units; data persists across app restarts
**Files**: `Sources/Views/Settings/SettingsView.swift`, `Sources/Views/Settings/BioDataView.swift`, `Sources/ViewModels/SettingsViewModel.swift`
**dependsOn**: T2

### T4: Settings Tab - Sport Types & Heart Rate Zones
Manage custom sport types and heart rate zone definitions.
- SportType CRUD: list, add, edit (name, abbreviation, color, favorite), delete
- HeartRateZone CRUD: list, add, edit (name, min/max HR), delete
- Default sport types seeded on first launch (Running, Cycling, Hiking, Walking, Swimming)
- Default HR zones seeded based on user age/VO2max if available
- Color picker for sport type color
**Acceptance**: User can add/edit/delete sport types and HR zones; defaults exist on first launch
**Files**: `Sources/Views/Settings/SportTypesView.swift`, `Sources/Views/Settings/HeartRateZonesView.swift`, `Sources/ViewModels/SportTypeViewModel.swift`, `Sources/ViewModels/HeartRateZoneViewModel.swift`
**dependsOn**: T2

## Phase 2: Workout Recording Engine

### T5: LocationManager Service
Implement the CoreLocation wrapper for GPS tracking.
- CLLocationManager wrapper with @Observable
- Request "When In Use" and "Always" authorization
- Background location updates with fitness activity type
- Publish: current location, heading, authorization status
- Configurable accuracy (best vs reduced for battery)
- Handle authorization changes gracefully
**Acceptance**: Manager requests location permission, provides live coordinates, works in background
**Files**: `Sources/Services/LocationManager.swift`
**dependsOn**: T1

### T6: WorkoutRecorder State Machine
Build the core recording engine with state management and auto-save.
- State machine: idle → setup → recording → paused → completed
- Timer management (elapsed time with pause support)
- Track point accumulation from LocationManager
- Sensor sample accumulation (HR data when available)
- Distance calculation (Haversine formula between track points)
- Elevation gain calculation (sum of positive altitude deltas)
- Auto-save every 30 seconds
- Crash recovery: persist in-progress workout state, detect and offer recovery on relaunch
**Acceptance**: Can start/pause/resume/stop workout; distance and elevation calculate correctly; auto-save persists data; incomplete workout detected on relaunch
**Files**: `Sources/Services/WorkoutRecorder.swift`, `Sources/Utilities/DistanceCalculator.swift`
**dependsOn**: T2, T5

### T7: Record Tab - Setup Screen
Build the pre-workout configuration screen.
- Sport type picker (from user-defined types, favorites first)
- Intensity level picker
- Optional note text field
- GPS toggle (on/off)
- Sensor selection (if BLE HR connected)
- Start workout button → transitions to live view
- Navigation to live view via sheet or NavigationStack push
**Acceptance**: User can configure all workout parameters before starting; start button transitions to live recording
**Files**: `Sources/Views/Record/WorkoutSetupView.swift`, `Sources/ViewModels/WorkoutSetupViewModel.swift`
**dependsOn**: T4, T6

### T8: Record Tab - Live View
Build the active workout display with real-time metrics.
- Large, high-contrast timer display
- Distance, pace/speed, calories, HR, elevation metrics
- Pause / Resume / Stop buttons (large, accessible)
- Metric layout: 2-3 column grid for metrics during recording
- Calorie calculation based on user bio data, sport type, duration, HR
- Pace = duration / distance (running) or speed = distance / duration (cycling)
**Acceptance**: Metrics update in real-time during recording; pause/resume works correctly; stop saves workout
**Files**: `Sources/Views/Record/WorkoutLiveView.swift`, `Sources/ViewModels/WorkoutLiveViewModel.swift`
**dependsOn**: T6, T7

### T9: Record Tab - Map Overlay
Add map view showing live GPS track during recording.
- MapKit integration via SwiftUI Map { } wrapper
- MKPolyline overlay for recorded track
- Current position annotation (blue dot)
- Auto-center on current position
- Zoom to fit track extent
- Toggle between map and metrics view
**Acceptance**: Map shows during recording; track renders as polyline; auto-centers on user; toggle works
**Files**: `Sources/Views/Record/WorkoutMapView.swift`
**dependsOn**: T8

## Phase 3: BLE Sensor Integration

### T10: SensorManager Service
Implement the CoreBluetooth wrapper for BLE heart rate sensors.
- CBCentralManager wrapper with @Observable
- Scan for HR service UUID (0x180D)
- Pair and connect to peripheral
- Remember paired peripheral identifier in UserDefaults
- Auto-reconnect to known peripheral on app launch
- Stream live HR values via published property
- Read battery level (UUID 0x2A19)
- HeartRateSource protocol for future extensibility
- Sensor status: disconnected, scanning, connected, error
**Acceptance**: Can discover, pair, and receive live HR from a BLE sensor; persists peripheral across restarts; battery level readable
**Files**: `Sources/Services/SensorManager.swift`, `Sources/Services/HeartRateSource.swift`
**dependsOn**: T1

### T11: BLE Integration in Record Flow
Connect SensorManager to the workout recording pipeline.
- SensorManager feeds HR samples into WorkoutRecorder during recording
- HR display in live view updates in real-time
- HR zone calculation using user-defined zones
- Sensor status indicator in live view (connected/disconnected/battery)
- Graceful handling when sensor disconnects mid-workout
**Acceptance**: HR values appear in live view during recording; HR zones calculate correctly; disconnect handled gracefully
**Files**: `Sources/Views/Record/WorkoutLiveView.swift` (update), `Sources/ViewModels/WorkoutLiveViewModel.swift` (update)
**dependsOn**: T8, T10

### T12: Sensor Diagnostics
Display sensor connection status and diagnostic information.
- Sensor status card: connection state, device name, battery level
- Signal strength indicator if available
- Reconnect button when disconnected
- Display in Settings or as a sheet from Record tab
**Acceptance**: Sensor diagnostics visible; user can see connection state and battery; reconnect button works
**Files**: `Sources/Views/Settings/SensorDiagnosticsView.swift`
**dependsOn**: T10

## Phase 4: History + Analysis + Charts

### T13: History Tab - Workout List
Build the chronological workout list with search and filter.
- @Query sorted by startTime descending
- List rows: date, sport type (color dot), duration, distance
- Pull-to-refresh or live update via SwiftData
- Search by note text
- Filter by sport type, date range
- Swipe actions: edit, delete (with confirmation)
**Acceptance**: All workouts listed chronologically; search and filter work; edit and delete functional
**Files**: `Sources/Views/History/WorkoutListView.swift`, `Sources/ViewModels/WorkoutListViewModel.swift`
**dependsOn**: T2

### T14: History Tab - Workout Detail
Build the workout detail view with metrics and map.
- Summary section: sport, date, duration, distance, calories, elevation, avg HR
- Map section: track polyline on MapKit
- Metrics section: key numbers in a grid
- Edit button: edit sport, intensity, note, date
- Delete button with confirmation
- Share/export button (GPX export, Phase 5)
**Acceptance**: Detail shows all workout metrics; map renders track; edit and delete work
**Files**: `Sources/Views/History/WorkoutDetailView.swift`, `Sources/ViewModels/WorkoutDetailViewModel.swift`
**dependsOn**: T13

### T15: History Tab - Manual Entry
Build the form for manually logging a workout.
- Sport type picker
- Date and time pickers
- Duration picker
- Distance, calories, elevation input fields
- Intensity picker
- Optional note
- Save → adds to workout history
**Acceptance**: Manual workout saved with correct data; appears in history list
**Files**: `Sources/Views/History/ManualWorkoutView.swift`
**dependsOn**: T2

### T16: Analysis Tab - Charts
Build workout detail charts using Swift Charts.
- HR over time (line chart, color-coded by zone)
- Pace/speed over time (line chart)
- Elevation profile (area chart)
- Zoomable via .chartOverlay + DragGesture
- Period selector (last 7 days, 30 days, year, all)
- Weekly aggregate bar chart (total distance, duration, count)
**Acceptance**: Charts render correctly for recorded workouts; zoom/pan works; period selection filters data
**Files**: `Sources/Views/Analysis/AnalysisView.swift`, `Sources/Views/Analysis/HRChartView.swift`, `Sources/Views/Analysis/PaceChartView.swift`, `Sources/Views/Analysis/ElevationChartView.swift`, `Sources/ViewModels/AnalysisViewModel.swift`
**dependsOn**: T14

### T17: Analysis Tab - Period Comparison
Build period-over-period comparison views.
- Weekly summary: total workouts, distance, duration, calories, elevation
- Compare current week vs previous week
- Percentage change indicators
- Drill-down from summary to individual workouts
**Acceptance**: Period comparison shows correct aggregates; drill-down navigates to workout detail
**Files**: `Sources/Views/Analysis/PeriodComparisonView.swift`, `Sources/ViewModels/PeriodComparisonViewModel.swift`
**dependsOn**: T16

## Phase 5: GPX Module + Goals + Notifications

### T18: GPX Parser
Build the GPX file parser module.
- XMLParser-based streaming parser
- Parse GPX 1.1 format: metadata, waypoints, tracks, track segments
- Extract: coordinates, elevation, time, speed, course
- Handle large files efficiently (streaming, not DOM)
- Error handling for malformed GPX
- Unit tests for parser
**Acceptance**: Parser correctly extracts track points from valid GPX files; handles malformed input gracefully
**Files**: `Sources/GPX/GPXParser.swift`, `Sources/GPX/GPXDocument.swift`
**dependsOn**: T1

### T19: GPX Exporter
Build the GPX file export module.
- Generate valid GPX 1.1 XML from workout + track points
- Include metadata (name, time, sport type)
- Include track segment with lat, lon, elevation, time
- Export to temporary file for Share Sheet
- Unit tests for exporter
**Acceptance**: Exported GPX is valid GPX 1.1; contains all track points; importable by other apps
**Files**: `Sources/GPX/GPXExporter.swift`
**dependsOn**: T18

### T20: GPX Import/Export UI
Build the import and export user interfaces.
- Export: Share Sheet triggered from workout detail
- Import: DocumentPicker for .gpx files
- Import flow: parse GPX → create Workout (manual type) → import track points → save
- Show import progress for large files
- Handle duplicate imports (by timestamp or coordinates)
**Acceptance**: Export via Share Sheet works; import via DocumentPicker creates workout with track data
**Files**: `Sources/Views/History/GPXImportView.swift`, `Sources/ViewModels/GPXViewModel.swift`
**dependsOn**: T14, T18, T19

### T21: Goals Tab & Tracking
Implement the weekly goals system.
- Goal CRUD: set targets for workouts/week, duration/week, calories/week, distance/week, elevation/week
- Goal weight/priority for progress calculation
- Progress tracking: calculate current week's progress toward each goal
- Progress view: percentage bars, visual weekly status
- Goal completion indicators
**Acceptance**: User can set/edit goals; progress calculates correctly against current week data
**Files**: `Sources/Views/Settings/GoalsView.swift`, `Sources/ViewModels/GoalsViewModel.swift`
**dependsOn**: T2, T13

### T22: Notifications System
Implement local notifications for goals and reminders.
- Daily workout reminder at configurable time
- Goal progress notifications (e.g., "You've reached 75% of your weekly distance goal")
- Notification permission request flow
- Notification scheduling via UNUserNotificationCenter
**Acceptance**: Daily reminder fires at set time; goal progress notifications work; permissions handled
**Files**: `Sources/Services/NotificationManager.swift`, `Sources/Views/Settings/NotificationSettingsView.swift`
**dependsOn**: T21

### T23: Home Tab
Build the home screen with stats and last workout.
- Last workout card: date, sport, duration, relative time
- Live workout status card (when recording active)
- Stats summary cards: last 7 days (default), toggleable periods
- Stats: workout count, total duration, distance, calories, elevation
- Toggle: absolute / per week / percentage
- Tap stat → detail drill-down
**Acceptance**: Home shows last workout and stats; live status updates during recording; period toggle works
**Files**: `Sources/Views/Home/HomeView.swift`, `Sources/Views/Home/LastWorkoutCard.swift`, `Sources/Views/Home/StatsCardView.swift`, `Sources/ViewModels/HomeViewModel.swift`
**dependsOn**: T2, T6

### T24: App Integration & Polish
Final integration pass connecting all components.
- Tab bar with correct navigation
- ModelContainer registration of all models
- Service initialization order (LocationManager → SensorManager → WorkoutRecorder)
- App lifecycle: check for incomplete workouts on launch
- Error handling and user-facing alerts
- Accessibility: VoiceOver labels, Dynamic Type support
- High contrast workout view validation
**Acceptance**: App launches cleanly; all tabs navigable; services initialize in order; crash recovery works
**Files**: `Sources/App/myWorkoutsApp.swift`, `Sources/App/ContentView.swift` (updates)
**dependsOn**: T11, T12, T17, T20, T22, T23

## Dependency Graph

```
T1 ─┬─→ T2 ─┬─→ T3
    │        ├─→ T4
    │        ├─→ T6 ─→ T7 ─→ T8 ─→ T9
    │        │         ↑
    │        │        T5 ──┘
    │        ├─→ T13 ─→ T14 ─→ T16 ─→ T17
    │        │         ↑
    │        │        T15
    │        ├─→ T21 ─→ T22
    │        └─→ T23
    ├─→ T10 ─→ T11, T12
    └─→ T18 ─→ T19 ─→ T20

T24 integrates: T11, T12, T17, T20, T22, T23
```

## Parallelism Opportunities

- **Parallel batch 1**: T1 (must be first)
- **Parallel batch 2**: T2, T10, T18 (independent after scaffold)
- **Parallel batch 3**: T3, T4, T5, T13, T15, T19 (independent after models)
- **Parallel batch 4**: T6, T11, T12, T14, T20, T21, T23 (after their dependencies)
- **Parallel batch 5**: T7, T8, T16, T22
- **Parallel batch 6**: T9, T17
- **Final**: T24 (integration)
