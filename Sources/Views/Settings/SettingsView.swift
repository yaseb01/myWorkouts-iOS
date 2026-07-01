import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Bio Data") {
                LabeledContent("Gender", value: "Not set")
                LabeledContent("Birth Date", value: "Not set")
                LabeledContent("Weight", value: "Not set")
                LabeledContent("Height", value: "Not set")
                LabeledContent("VO2 Max", value: "Not set")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Bio data settings")

            Section("Units") {
                Picker("Unit System", selection: .constant(UnitSystem.metric)) {
                    Text("Metric").tag(UnitSystem.metric)
                    Text("Imperial").tag(UnitSystem.imperial)
                }
                .accessibilityLabel("Unit system selector")
            }

            Section("Sport Types") {
                Text("Manage sport types")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Sport types settings")

            Section("Heart Rate Zones") {
                Text("Manage heart rate zones")
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Heart rate zone settings")

            Section("About") {
                LabeledContent("Version", value: "1.0")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .navigationTitle("Settings")
    }
}
