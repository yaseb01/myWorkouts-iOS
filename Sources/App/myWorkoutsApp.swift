import SwiftUI
import SwiftData

@main
struct myWorkoutsApp: App {
    var modelContainer: ModelContainer {
        let schema = Schema([
            // Models will be registered here as they are created
            // For now, an empty schema is sufficient for the tab bar scaffold
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
