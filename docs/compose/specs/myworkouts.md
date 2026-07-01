# Specification: myWorkouts iOS App

> [!NOTE]
> This document may not reflect the current implementation.
> See the final report for up-to-date state:
> [Final Report](../reports/myworkouts.md)

## Overview

Native iOS fitness tracking app built with SwiftUI + SwiftData. 5-tab navigation (Home, Record, History, Analysis, Settings). Local-only data storage, no cloud sync. BLE heart rate sensor integration. GPX import/export. Targets iPhone, iOS 17+.

## Target Users

- Outdoor athletes (runners, cyclists, hikers) needing GPS, distance, elevation
- Heart rate-focused trainers wanting pulse zone analysis
- Structured self-trackers wanting history, stats, goals, manual entry

## Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Start, pause, resume, stop a workout with time tracking | Must |
| FR-02 | Record GPS track, distance, elevation | Must |
| FR-03 | BLE heart rate sensor support | Must |
| FR-04 | Store and display workout history locally | Must |
| FR-05 | Manual workout entry (no live recording) | Must |
| FR-06 | Workout detail with metrics and at least one chart | Must |
| FR-07 | GPX file import and export | Should |
| FR-08 | Periodic statistics and goal tracking | Should |
| FR-09 | Offline maps or comparable offline mode | Should |
| FR-10 | Sensor and recording status diagnostics | Could |

## Technical Architecture

### Stack
- **UI**: SwiftUI declarative, UIKit bridges only where SwiftUI falls short (maps, specialized charts)
- **Persistence**: SwiftData (@Model macros, @Query, predicates, sorting)
- **Location**: CoreLocation (GPS, background updates, fitness activity type)
- **Sensors**: CoreBluetooth (BLE HR service UUID 0x180D)
- **Charts**: Swift Charts (iOS 16+)
- **Maps**: MapKit (Apple Maps, MKPolyline overlay)
- **Notifications**: UserNotifications (local, daily reminders)
- **Min target**: iOS 17

### Architecture Pattern
MVVM with @Observable (iOS 17 Observation framework). ViewModels inject services. No TCA, no third-party dependencies.

### Project Structure
Single-target Xcode project, feature-based folder organization:
```
Sources/
  App/                          # App entry point, model container setup
  Models/                       # SwiftData @Model classes
  Views/
    Home/                       # Home tab
    Record/                     # Workout recording tab
    History/                    # Training log tab
    Analysis/                   # Analysis tab
    Settings/                   # Settings tab
    Shared/                     # Reusable view components
  ViewModels/                   # @Observable view models
  Services/                     # LocationManager, SensorManager, WorkoutRecorder, NotificationManager
  GPX/                          # GPX parser and exporter (self-contained)
  Utilities/                    # Extensions, formatters, constants
```

## Data Models

### Workout
- id: UUID
- sportType: SportType (relationship)
- startTime: Date
- endTime: Date?
- duration: TimeInterval
- distance: Double (meters)
- calories: Double
- elevationGain: Double (meters)
- note: String?
- intensity: IntensityLevel
- isManual: Bool (manual entry vs recorded)
- trackPoints: [TrackPoint] (relationship)
- sensorSamples: [SensorSample] (relationship)
- heartRateZoneSummary: [ZoneDuration]?

### TrackPoint
- timestamp: Date
- latitude: Double
- longitude: Double
- altitude: Double?
- horizontalAccuracy: Double?
- speed: Double?
- course: Double?

### SensorSample
- timestamp: Date
- type: SensorType (heartRate, cadence, speed, temperature)
- value: Double
- unit: String

### Goal
- id: UUID
- type: GoalType (workouts, duration, calories, distance, elevation)
- weeklyTarget: Double
- unit: String
- weight: Int (priority weighting)
- isActive: Bool

### SportType
- id: UUID
- name: String
- abbreviation: String
- color: String (hex)
- isFavorite: Bool

### HeartRateZone
- id: UUID
- name: String
- abbreviation: String
- minHR: Int
- maxHR: Int
- zoneNumber: Int

### UserProfile
- gender: Gender?
- birthDate: Date?
- weight: Double?
- height: Double?
- vo2max: Double?

## Tab Breakdown

### Home Tab
- Last workout card (date, sport, duration, relative time)
- Live workout status (when recording active)
- Stats cards: weekly/monthly/yearly/total with toggle (absolute / per week / percentage)
- Tap stat for detail drill-down

### Record Tab
- Pre-start setup: sport type, intensity, note, GPS toggle, sensor selection
- Live view: timer, distance, pace/speed, calories, HR, elevation
- Pause / Resume / Stop controls
- Map overlay with track, auto-center, zoom
- Auto-save every 30s, crash recovery on relaunch
- Background recording via CLLocationManager (fitness activity type)

### History Tab
- Chronological workout list with metadata
- Search and filter (by sport, date range)
- Detail view: metrics, charts, map
- Manual entry form
- Edit existing workouts
- Delete with confirmation

### Analysis Tab
- Workout detail metrics (duration, avg HR, distance, calories, elevation)
- HR over time (line chart)
- Pace/speed over time (line chart)
- Elevation profile (area chart)
- Zoomable charts via .chartOverlay + DragGesture
- Period comparison (weekly aggregation)

### Settings Tab
- Bio data (gender, birth date, weight, height, VO2max)
- Heart rate zones (define/edit zones)
- Sport types (add/edit/delete, name, abbreviation, color, favorite)
- Units (metric/imperial)
- Privacy, license, version, support pages

## Services

### LocationManager
- Wraps CLLocationManager
- Foreground + background location updates
- Activity type: .fitness
- Publishes: current location, authorization status
- Configurable: accuracy, background mode

### SensorManager (BLE)
- Wraps CBCentralManager
- Scans for HR service (UUID 0x180D)
- Pair, remember (persist peripheral identifier), reconnect
- Live HR value streaming
- Battery level reading (UUID 0x2A19)
- Protocol-based (HeartRateSource) for future extensibility
- @Observable, publishes to views

### WorkoutRecorder
- State machine: idle → setup → recording → paused → completed
- Manages timer, GPS track accumulation, sensor sample recording
- Auto-save every 30 seconds
- Crash recovery: detect incomplete workout on relaunch, offer recovery
- Background execution via CLLocationManager

### NotificationManager
- Local notifications for daily workout reminders
- Configurable time
- Goal progress notifications

## GPX Module
- Standalone Swift module (no external deps)
- GPXParser: XMLParser-based, streaming for large tracks
- GPXExporter: generates valid GPX 1.1 XML
- Handles: waypoints, tracks, track segments, elevation, time, coordinates
- Import via iOS DocumentPicker
- Export via Share Sheet

## Non-Functional Requirements

- Stable during long outdoor activities with regular auto-save
- Recording must work with screen locked (within iOS background rules)
- High-contrast, sunlight-readable workout view
- Privacy by default: local storage, transparent permissions
- Functional without account or cloud sync
- All code, identifiers, comments in English; UI strings in English (localization deferred)
