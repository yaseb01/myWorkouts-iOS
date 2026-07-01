import SwiftUI

struct AnalysisView: View {
    var supportsVoiceOver: Bool { true }

    var body: some View {
        List {
            Section("Period") {
                Picker("Period", selection: .constant("7 Days")) {
                    Text("7 Days").tag("7 Days")
                    Text("30 Days").tag("30 Days")
                    Text("Year").tag("Year")
                    Text("All").tag("All")
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Analysis time period")
            }

            Section("Summary") {
                HStack {
                    StatCard(title: "Workouts", value: "0")
                    StatCard(title: "Distance", value: "0 km")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Analysis summary: 0 workouts, 0 kilometers")
            }

            Section("Charts") {
                Text("HR chart placeholder")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Heart rate chart placeholder")
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        AnalysisView()
            .navigationTitle("Analysis")
    }
}
