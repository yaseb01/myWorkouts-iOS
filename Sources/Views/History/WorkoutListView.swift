import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]

    var body: some View {
        Group {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts",
                    systemImage: "figure.run",
                    description: Text("Record your first workout to see it here.")
                )
                .accessibilityLabel("No workouts recorded yet")
            } else {
                List(workouts) { workout in
                    WorkoutRow(workout: workout)
                }
            }
        }
    }
}

private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack {
            Circle()
                .fill(.blue)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                Text(workout.sportType?.name ?? "Workout")
                    .font(.headline)
                Text(workout.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formatDuration(workout.duration))
                    .font(.subheadline)
                Text(String(format: "%.1f km", workout.distance / 1000))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.sportType?.name ?? "Workout"), \(formatDuration(workout.duration)), \(String(format: "%.1f km", workout.distance / 1000))")
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    NavigationStack {
        WorkoutListView()
            .navigationTitle("History")
    }
    .modelContainer(for: [Workout.self, SportType.self], inMemory: true)
}
