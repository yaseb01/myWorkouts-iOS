import SwiftUI
import SwiftData

struct ManualWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \SportType.name) private var sportTypes: [SportType]

    @State private var selectedSportType: SportType?
    @State private var intensity: IntensityLevel = .moderate
    @State private var startTime = Date()
    @State private var durationMinutes: Double = 30
    @State private var distance: Double = 0
    @State private var calories: Double = 0
    @State private var elevationGain: Double = 0
    @State private var note: String = ""

    var body: some View {
        Form {
            Section("Sport") {
                Picker("Sport Type", selection: $selectedSportType) {
                    Text("None").tag(nil as SportType?)
                    ForEach(sportTypes) { sport in
                        Text(sport.name).tag(sport as SportType?)
                    }
                }
            }

            Section("Time") {
                DatePicker("Start Time", selection: $startTime)
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("min", value: $durationMinutes, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("min")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Metrics") {
                HStack {
                    Text("Distance")
                    Spacer()
                    TextField("km", value: $distance, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("km")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("kcal", value: $calories, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("kcal")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Elevation")
                    Spacer()
                    TextField("m", value: $elevationGain, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("m")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Intensity") {
                Picker("Intensity", selection: $intensity) {
                    ForEach(IntensityLevel.allCases, id: \.self) { level in
                        Text(level.name).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Notes") {
                TextEditor(text: $note)
                    .frame(minHeight: 60)
            }

            Section {
                Button("Save Workout") {
                    saveWorkout()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .disabled(durationMinutes <= 0)
            }
        }
        .navigationTitle("Manual Entry")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveWorkout() {
        let endTime = startTime.addingTimeInterval(durationMinutes * 60)
        let workout = Workout(
            sportType: selectedSportType,
            startTime: startTime,
            endTime: endTime,
            duration: durationMinutes * 60,
            distance: distance * 1000,
            calories: calories,
            elevationGain: elevationGain,
            note: note.isEmpty ? nil : note,
            intensity: intensity,
            isManual: true
        )

        modelContext.insert(workout)
        try? modelContext.save()
        dismiss()
    }
}
