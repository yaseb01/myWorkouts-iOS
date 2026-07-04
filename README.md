# myWorkouts - iOS Fitness Tracker

A native iOS fitness tracking app for recording workouts with GPS, heart rate monitoring, and comprehensive training analysis.

## Features

### Workout Recording
- Start, pause, resume, and stop workouts
- Real-time GPS tracking with distance, pace, and elevation
- Bluetooth Low Energy heart rate sensor support
- Live metrics: timer, distance, pace, BPM, calories, elevation
- Map view with live track overlay
- Auto-save and crash recovery

### Training History
- Chronological workout list with sport type and intensity badges
- Search and filter workouts
- Manual workout entry
- Edit and delete workouts
- Workout detail view with Facts, Charts, and Heart Rate tabs

### Analysis
- Period-based statistics (7 days, 30 days, 1 year, total)
- Percentage comparison against reference periods
- Heart rate charts and histograms
- Distance and elevation over time
- Color-coded performance indicators

### Heart Rate Zones
- Customizable heart rate zones (Z0-Z5)
- Zone distribution bar during and after workouts
- Time-in-zone tracking
- Percentage-based zone definitions

### Workout Types
- Custom sport types with abbreviations and colors
- Favorite sport types for quick access
- 11 pre-configured sport types

### Goals & Motivation
- Weekly goals for workouts, duration, calories, distance, elevation
- Progress tracking with visual indicators
- Daily notification reminders

### Settings
- Biological data (gender, birth date, weight, height, VO2max)
- Metric and imperial unit support
- Training intensity/zone configuration
- Workout type management
- Privacy policy and feedback links

### GPX Support
- Import GPX files
- Export workouts as GPX
- Share via iOS Share Sheet

## Tech Stack

- **UI**: SwiftUI
- **Persistence**: SwiftData
- **Location**: CoreLocation
- **Sensors**: CoreBluetooth (BLE HR)
- **Charts**: Swift Charts
- **Maps**: MapKit
- **Minimum**: iOS 17

## Project Structure

```
Sources/
├── App/                    # App entry point and content view
├── Models/                 # SwiftData models
│   ├── Workout.swift
│   ├── TrackPoint.swift
│   ├── SensorSample.swift
│   ├── Goal.swift
│   ├── SportType.swift
│   ├── HeartRateZone.swift
│   ├── UserProfile.swift
│   └── Enums.swift
├── Services/               # Core services
│   ├── LocationManager.swift
│   ├── SensorManager.swift
│   ├── WorkoutRecorder.swift
│   └── GPXManager.swift
└── Views/                  # UI views
    ├── Home/               # Home screen with stats
    ├── Record/             # Workout setup, live view, map
    ├── History/            # Workout list and detail
    ├── Analysis/           # Charts and statistics
    ├── Goals/              # Goal management
    └── Settings/           # App settings
```

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yaseb01/myWorkouts-iOS.git
   ```

2. Open in Xcode:
   ```bash
   open myWorkouts.xcodeproj
   ```

3. Select a simulator or device and run.

## Permissions

The app requires:
- **Location**: GPS tracking during workouts
- **Bluetooth**: Heart rate sensor connection
- **Notifications**: Daily goal reminders

## License

See [Terms of Use](https://www.myworkouts.org/terms-of-use) and [Privacy Policy](https://www.myworkouts.org/privacy).
