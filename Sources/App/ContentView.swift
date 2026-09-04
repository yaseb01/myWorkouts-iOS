import SwiftUI
import SwiftData

/* AppLanguage - Language Management */

enum AppLanguage: String, CaseIterable, Identifiable, Equatable {
    case system = "system"
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return Locale.current
        case .english: return Locale(identifier: "en")
        case .german: return Locale(identifier: "de")
        }
    }
}

final class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()

    private let userDefaultsKey = "appLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: userDefaultsKey)
            objectWillChange.send()
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let language = AppLanguage(rawValue: saved) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .system
        }
    }
}

/* Localization - Manual bundle selection based on AppLanguageManager */

extension String {
    func localized() -> String {
        let langId: String
        switch AppLanguageManager.shared.currentLanguage {
        case .system:
            langId = Bundle.main.preferredLocalizations.first ?? "en"
        case .english:
            langId = "en"
        case .german:
            langId = "de"
        }

        let lprojPath = Bundle.main.bundlePath + "/\(langId).lproj"
        guard let bundle = Bundle(path: lprojPath) else {
            return self
        }

        let value = bundle.localizedString(forKey: self, value: nil, table: nil)
        return value == self ? self : value
    }
}

/* Root View with Language Observation */

struct LocaleProvider<Content: View>: View {
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .id(languageManager.currentLanguage)
    }
}

/* ContentView */

struct ContentView: View {
    @State private var selectedTab = 0

    var tabCount: Int {
        5
    }

    var tabIdentifiers: [String] {
        ["home", "record", "history", "analysis", "settings"]
    }

    var tabAccessibilityLabels: [String] {
        ["Home", "Record", "History", "Analysis", "Settings"]
    }

    var supportsDynamicType: Bool { true }

    var supportsHighContrast: Bool { true }

    private enum Tab: Int, CaseIterable {
        case home, record, history, analysis, settings

        var titleKey: String {
            switch self {
            case .home: return "Tab.Home"
            case .record: return "Tab.Record"
            case .history: return "Tab.History"
            case .analysis: return "Tab.Analysis"
            case .settings: return "Tab.Settings"
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
                HomeView()
                    .navigationTitle("Tab.Home".localized())
            }
            .tabItem {
                Label("Tab.Home".localized(), systemImage: "house")
            }
            .tag(0)
            .accessibilityLabel("Home tab")

            NavigationStack {
                WorkoutSetupView()
                    .navigationTitle("Tab.Record".localized())
            }
            .tabItem {
                Label("Tab.Record".localized(), systemImage: "circle.fill")
            }
            .tag(1)
            .accessibilityLabel("Record tab")

            NavigationStack {
                WorkoutListView()
                    .navigationTitle("Tab.History".localized())
            }
            .tabItem {
                Label("Tab.History".localized(), systemImage: "clock.arrow.circlepath")
            }
            .tag(2)
            .accessibilityLabel("History tab")

            NavigationStack {
                AnalysisView()
                    .navigationTitle("Tab.Analysis".localized())
            }
            .tabItem {
                Label("Tab.Analysis".localized(), systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(3)
            .accessibilityLabel("Analysis tab")

            NavigationStack {
                SettingsView()
                    .navigationTitle("Tab.Settings".localized())
            }
            .tabItem {
                Label("Tab.Settings".localized(), systemImage: "gearshape")
            }
            .tag(4)
            .accessibilityLabel("Settings tab")
        }
        .accessibilityElement(children: .contain)
        .preferredColorScheme(.dark)
    }
}
