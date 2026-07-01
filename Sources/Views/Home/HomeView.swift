import SwiftUI

struct HomeView: View {
    var body: some View {
        List {
            Section("Last Workout") {
                Text("No workouts yet")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("No workouts recorded yet")
            }

            Section("This Week") {
                HStack {
                    StatItem(label: "Workouts", value: "0")
                    StatItem(label: "Duration", value: "0 min")
                    StatItem(label: "Distance", value: "0 km")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Weekly statistics: 0 workouts, 0 minutes, 0 kilometers")
            }
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .navigationTitle("Home")
    }
}
