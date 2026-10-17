import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedSportFilter: String? = nil
    @State private var showManualEntry = false
    @State private var showGPXImport = false
    @State private var workoutToDelete: Workout?

    private var filteredWorkouts: [Workout] {
        var result = workouts

        if !searchText.isEmpty {
            result = result.filter { workout in
                (workout.sportType?.name.localizedCaseInsensitiveContains(searchText) == true) ||
                (workout.note?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }

        if let filter = selectedSportFilter {
            result = result.filter { $0.sportType?.name == filter }
        }

        return result
    }

    var body: some View {
        Group {
            if workouts.isEmpty {
                ContentUnavailableView(
                    "History.NoWorkouts".localized(),
                    systemImage: "figure.run",
                    description: Text("History.RecordFirst".localized())
                )
            } else {
                List {
                    ForEach(filteredWorkouts) { workout in
                        NavigationLink {
                            WorkoutDetailView(workout: workout)
                        } label: {
                            WorkoutRow(workout: workout)
                        }
                        .listRowBackground(Color(.systemBackground))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                workoutToDelete = workout
                            } label: {
                                Label("Delete".localized(), systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "History.SearchPlaceholder".localized())
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("History.Title".localized())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showManualEntry = true
                    } label: {
                        Label("Manual.ManualEntry".localized(), systemImage: "plus.circle")
                    }

                    Button {
                        showGPXImport = true
                    } label: {
                        Label("GPX.Import".localized(), systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.green)
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            NavigationStack {
                ManualWorkoutView()
            }
        }
        .sheet(isPresented: $showGPXImport) {
            GPXImportView()
        }
        .confirmationDialog(
            "History.DeleteWorkout".localized(),
            isPresented: Binding(
                get: { workoutToDelete != nil },
                set: { if !$0 { workoutToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete".localized(), role: .destructive) {
                if let workout = workoutToDelete {
                    modelContext.delete(workout)
                    try? modelContext.save()
                }
                workoutToDelete = nil
            }
            Button("Cancel".localized(), role: .cancel) { }
        } message: {
            Text("History.DeleteWorkoutMessage".localized())
        }
    }
}

// MARK: - Workout Row (Android-style)

private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 10) {
            // Intensity badge (circle with abbreviation)
            Circle()
                .fill(WorkoutColors.intensity(workout.intensity))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(workout.intensity.abbreviation)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

            // Sport type badge (rounded square with abbreviation)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: workout.sportType?.color ?? "#007AFF") ?? .blue)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(workout.sportType?.abbreviation ?? "?")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }

            // Info
            VStack(alignment: .leading, spacing: 1) {
                Text(workout.startTime, format: .dateTime.month().day())
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text("\(formatDuration(workout.duration))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
                if !workout.sensorSamples.filter({ $0.type == .heartRate }).isEmpty {
                    let avgHR = workout.sensorSamples.filter({ $0.type == .heartRate }).map(\.value).reduce(0, +) /
                        Double(max(1, workout.sensorSamples.filter({ $0.type == .heartRate }).count))
                    Text("\(Int(avgHR)) bpm avg")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            // Note
            if let note = workout.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 120, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        DurationFormat.clock(seconds)
    }
}
