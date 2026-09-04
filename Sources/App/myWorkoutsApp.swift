import SwiftUI
import SwiftData

@main
struct myWorkoutsApp: App {
    @State private var locationManager = LocationManager()
    @State private var sensorManager = SensorManager()
    @State private var workoutRecorder = WorkoutRecorder()
    @State var modelContainer: ModelContainer?

    init() {
        _ = AppLanguageManager.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    LocaleProvider {
                        ContentView()
                            .environment(locationManager)
                            .environment(sensorManager)
                            .environment(workoutRecorder)
                            .modelContainer(container)
                            .onAppear {
                                seedDefaultDataIfNeeded(context: container.mainContext)
                            }
                    }
                } else {
                    ProgressView()
                        .onAppear { setupContainer() }
                }
            }
        }
    }

    private func setupContainer() {
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
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            deleteOldDatabase()
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private func deleteOldDatabase() {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let fm = FileManager.default
        let storeURL = url.appendingPathComponent("default.store")
        try? fm.removeItem(at: storeURL)
        try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
        try? fm.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
        let appStoreURL = url.appendingPathComponent("myWorkouts.store")
        try? fm.removeItem(at: appStoreURL)
        try? fm.removeItem(at: URL(fileURLWithPath: appStoreURL.path + "-wal"))
        try? fm.removeItem(at: URL(fileURLWithPath: appStoreURL.path + "-shm"))
    }

    private func seedDefaultDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<SportType>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let sportDefaults: [(String, String, String, Bool)] = [
            ("Cycling", "CYC", "#007AFF", true),
            ("Elliptical Trainer", "ELT", "#00C7BE", false),
            ("Fitness Training", "FIT", "#34C759", true),
            ("Flying", "FLY", "#FF9500", false),
            ("Gymnastics", "GYM", "#007AFF", false),
            ("Hiking", "HKG", "#8BC34A", false),
            ("Horse Riding", "RID", "#34C759", false),
            ("Indoor Cycling", "IC", "#8E8E93", true),
            ("Running", "RUN", "#FF3B30", true),
            ("Swimming", "SWM", "#5856D6", false),
            ("Walking", "WLK", "#FF9500", false),
        ]

        for (name, abbr, color, fav) in sportDefaults {
            let sport = SportType(name: name, abbreviation: abbr, color: color, isFavorite: fav)
            context.insert(sport)
        }

        let zoneDefaults: [(String, String, Int, Int, Int, Double, Double)] = [
            ("Resting", "Resting (no workout)", 58, 122, 0, 0, 50),
            ("Easy", "Easy / Recovery", 122, 134, 1, 50, 60),
            ("Basic Endurance", "Basic Endurance, Fat Burning", 134, 147, 2, 60, 70),
            ("Tempo", "Tempo, Aerobic Fitness", 147, 160, 3, 70, 80),
            ("Threshold", "Hard, Anaerobic Zone", 160, 172, 4, 80, 90),
            ("Maximum", "Maximum Performance / Speed", 172, 185, 5, 90, 100),
        ]

        for (name, desc, min, max, num, minPct, maxPct) in zoneDefaults {
            let zone = HeartRateZone(
                name: name, zoneDescription: desc,
                minHR: min, maxHR: max, zoneNumber: num,
                minPercentage: minPct, maxPercentage: maxPct
            )
            context.insert(zone)
        }

        context.insert(UserProfile())

        try? context.save()
    }
}
