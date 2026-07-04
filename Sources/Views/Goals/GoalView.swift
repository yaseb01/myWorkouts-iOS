import SwiftUI
import SwiftData

struct GoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Goal> { $0.isActive }) private var activeGoals: [Goal]
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]

    @State private var showAddGoal = false

    var body: some View {
        List {
            Section("Weekly Progress") {
                weeklyProgressSection
            }

            Section("Goals") {
                if activeGoals.isEmpty {
                    Text("No goals set")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeGoals) { goal in
                        goalRow(goal)
                    }
                    .onDelete(perform: deleteGoals)
                }
            }

            Section {
                Button {
                    showAddGoal = true
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Goals")
        .sheet(isPresented: $showAddGoal) {
            AddGoalView()
        }
    }

    // MARK: - Weekly Progress

    private var weeklyProgressSection: some View {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekWorkouts = allWorkouts.filter { $0.startTime >= weekStart }

        return VStack(spacing: 12) {
            let totalWorkouts = weekWorkouts.count
            let totalDuration = weekWorkouts.reduce(0) { $0 + $1.duration } / 60
            let totalCalories = weekWorkouts.reduce(0) { $0 + $1.calories }
            let totalDistance = weekWorkouts.reduce(0) { $0 + $1.distance } / 1000

            progressRow(label: "Workouts", current: Double(totalWorkouts), goal: workoutsGoalTarget, unit: "")
            progressRow(label: "Duration", current: totalDuration, goal: durationGoalTarget, unit: "min")
            progressRow(label: "Distance", current: totalDistance, goal: distanceGoalTarget, unit: "km")
            progressRow(label: "Calories", current: totalCalories, goal: caloriesGoalTarget, unit: "kcal")
        }
        .padding(.vertical, 4)
    }

    private func progressRow(label: String, current: Double, goal: Double, unit: String) -> some View {
        let percentage = goal > 0 ? min(current / goal, 1.0) : 0

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(formattedValue(current, unit)) / \(formattedValue(goal, unit))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(percentage >= 1.0 ? .green : .blue)
                        .frame(width: geo.size.width * percentage)
                }
            }
            .frame(height: 8)
            Text("\(Int(percentage * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Goal Row

    private func goalRow(_ goal: Goal) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(goal.type.rawValue.capitalized)
                    .font(.headline)
                Text("Weight: \(goal.weight)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(goal.weeklyTarget)) \(goal.unit)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(activeGoals[index])
        }
        try? modelContext.save()
    }

    private var workoutsGoalTarget: Double {
        activeGoals.first(where: { $0.type == .workouts })?.weeklyTarget ?? 3
    }

    private var durationGoalTarget: Double {
        activeGoals.first(where: { $0.type == .duration })?.weeklyTarget ?? 150
    }

    private var distanceGoalTarget: Double {
        activeGoals.first(where: { $0.type == .distance })?.weeklyTarget ?? 20
    }

    private var caloriesGoalTarget: Double {
        activeGoals.first(where: { $0.type == .calories })?.weeklyTarget ?? 2000
    }

    private func formattedValue(_ value: Double, _ unit: String) -> String {
        if unit.isEmpty { return "\(Int(value))" }
        return "\(Int(value)) \(unit)"
    }
}

// MARK: - Add Goal View

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: GoalType = .workouts
    @State private var weeklyTarget: Double = 3
    @State private var weight: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }

                Section("Target") {
                    HStack {
                        Text("Weekly Goal")
                        Spacer()
                        TextField("Value", value: $weeklyTarget, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(selectedType.unit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Priority") {
                    Picker("Weight", selection: $weight) {
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button("Save Goal") {
                        let goal = Goal(
                            type: selectedType,
                            weeklyTarget: weeklyTarget,
                            weight: weight
                        )
                        modelContext.insert(goal)
                        try? modelContext.save()
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
