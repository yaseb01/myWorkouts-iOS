import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var selectedSportFilter: String? = nil
    @State private var showManualEntry = false
    @State private var showGPXImport = false

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
                                modelContext.delete(workout)
                                try? modelContext.save()
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
    }
}

// MARK: - Workout Row (Android-style)

private struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 10) {
            // Intensity badge (circle with abbreviation)
            Circle()
                .fill(Color(hex: intensityColor(for: workout.intensity)) ?? .gray)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(intensityAbbrev(for: workout.intensity))
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
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        let activeMinutes = Int(seconds) / 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func intensityColor(for level: IntensityLevel) -> String {
        switch level {
        case .easy: return "#8BC34A"      // Light green
        case .moderate: return "#9C27B0"  // Purple
        case .hard: return "#F44336"      // Red
        case .veryHard: return "#FF9800"  // Orange
        case .maximum: return "#FFEB3B"   // Yellow
        }
    }

    private func intensityAbbrev(for level: IntensityLevel) -> String {
        switch level {
        case .easy: return "G1"
        case .moderate: return "G2"
        case .hard: return "G3"
        case .veryHard: return "G4"
        case .maximum: return "G5"
        }
    }
}
