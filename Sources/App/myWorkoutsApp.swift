import SwiftUI
import SwiftData

@main
struct myWorkoutsApp: App {
    @State private var locationManager = LocationManager()
    @State private var sensorManager = SensorManager()
    @State private var workoutRecorder = WorkoutRecorder()

    var errorMessage: String?
    var showErrorAlert = false

    private let _modelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            TrackPoint.self,
            SensorSample.self,
            Goal.self,
            SportType.self,
            HeartRateZone.self,
            UserProfile.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var modelContainer: ModelContainer { _modelContainer }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .environment(sensorManager)
                .environment(workoutRecorder)
                .onAppear {
                    seedDefaultDataIfNeeded()
                }
        }
        .modelContainer(modelContainer)
    }

    private func seedDefaultDataIfNeeded() {
        guard let context = try? modelContainer.mainContext else { return }

        let descriptor = FetchDescriptor<SportType>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let defaults: [(String, String, String, Bool)] = [
            ("Running", "RUN", "#FF3B30", true),
            ("Cycling", "CYC", "#007AFF", false),
            ("Hiking", "HIK", "#34C759", false),
            ("Walking", "WLK", "#FF9500", false),
            ("Swimming", "SWM", "#5856D6", false),
        ]

        for (name, abbr, color, fav) in defaults {
            let sport = SportType(name: name, abbreviation: abbr, color: color, isFavorite: fav)
            context.insert(sport)
        }

        let defaultZones: [(String, Int, Int, Int)] = [
            ("Recovery", 95, 114, 1),
            ("Aerobic", 114, 133, 2),
            ("Tempo", 133, 152, 3),
            ("Threshold", 152, 171, 4),
            ("VO2 Max", 171, 190, 5),
        ]

        for (name, min, max, num) in defaultZones {
            let zone = HeartRateZone(name: name, minHR: min, maxHR: max, zoneNumber: num)
            context.insert(zone)
        }

        let profile = UserProfile()
        context.insert(profile)

        try? context.save()
    }
}
