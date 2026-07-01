import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var tabCount: Int {
        5
    }

    var tabIdentifiers: [String] {
        ["home", "record", "history", "analysis", "settings"]
    }

    private enum Tab: Int, CaseIterable {
        case home, record, history, analysis, settings

        var title: String {
            switch self {
            case .home: return "Home"
            case .record: return "Record"
            case .history: return "History"
            case .analysis: return "Analysis"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house"
            case .record: return "circle.fill"
            case .history: return "clock.arrow.circlepath"
            case .analysis: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Text("Home")
                    .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                Text("Record")
                    .navigationTitle("Record")
            }
            .tabItem {
                Label("Record", systemImage: "circle.fill")
            }
            .tag(1)

            NavigationStack {
                Text("History")
                    .navigationTitle("History")
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(2)

            NavigationStack {
                Text("Analysis")
                    .navigationTitle("Analysis")
            }
            .tabItem {
                Label("Analysis", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(3)

            NavigationStack {
                Text("Settings")
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(4)
        }
    }
}
