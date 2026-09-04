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
            Section("Manual.Sport".localized()) {
                Picker("Manual.SportType".localized(), selection: $selectedSportType) {
                    Text("Setup.None".localized()).tag(nil as SportType?)
                    ForEach(sportTypes) { sport in
                        Text(sport.name).tag(sport as SportType?)
                    }
                }
            }

            Section("Manual.Time".localized()) {
                DatePicker("Manual.StartTime".localized(), selection: $startTime)
                HStack {
                    Text("Detail.Duration".localized())
                    Spacer()
                    TextField("Manual.Min".localized(), value: $durationMinutes, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("Manual.Min".localized())
                        .foregroundStyle(.secondary)
                }
            }

            Section("Manual.Metrics".localized()) {
                HStack {
                    Text("Detail.Distance".localized())
                    Spacer()
                    TextField("Analysis.km".localized(), value: $distance, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("Analysis.km".localized())
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Detail.TotalCalories".localized())
                    Spacer()
                    TextField("Timer.kcal".localized(), value: $calories, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("Timer.kcal".localized())
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Detail.ElevationGain".localized())
                    Spacer()
                    TextField("Timer.m".localized(), value: $elevationGain, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("Timer.m".localized())
                        .foregroundStyle(.secondary)
                }
            }

            Section("Record.Intensity".localized()) {
                Picker("Record.Intensity".localized(), selection: $intensity) {
                    ForEach(IntensityLevel.allCases, id: \.self) { level in
                        Text(level.name).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Manual.Notes".localized()) {
                TextEditor(text: $note)
                    .frame(minHeight: 60)
            }

            Section {
                Button("Manual.SaveWorkout".localized()) {
                    saveWorkout()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .disabled(durationMinutes <= 0)
            }
        }
        .navigationTitle("Manual.ManualEntry".localized())
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
