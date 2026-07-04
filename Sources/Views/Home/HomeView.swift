import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(WorkoutRecorder.self) private var recorder
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]
    @Query(filter: #Predicate<Goal> { $0.isActive }) private var activeGoals: [Goal]

    @State private var displayMode: DisplayMode = .percentage

    enum DisplayMode {
        case absolute
        case percentage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                lastWorkoutSection
                Divider().background(Color.gray.opacity(0.3))
                statisticsSection
                if !activeGoals.isEmpty {
                    Divider().background(Color.gray.opacity(0.3))
                    goalsSection
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("myWorkouts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ManualWorkoutView()
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Last Workout

    private var lastWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST WORKOUT")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            if let last = allWorkouts.first {
                NavigationLink {
                    WorkoutDetailView(workout: last)
                } label: {
                    HStack(spacing: 12) {
                        // Badges stacked vertically
                        VStack(spacing: 8) {
                            // Intensity badge
                            Circle()
                                .fill(intensityColor(for: last.intensity))
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Text(last.intensity.abbreviation)
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                }
                            // Sport badge
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: last.sportType?.color ?? "#007AFF") ?? .blue)
                                .frame(width: 52, height: 52)
                                .overlay {
                                    Text(last.sportType?.abbreviation ?? "?")
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                }
                        }

                        // Workout info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(relativeDate(last.startTime))
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatDuration(last.duration))
                                    .font(.headline.monospacedDigit())
                                    .foregroundStyle(.white)
                                Text("(\(Int(last.duration / 60))')")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if lastAvgHR(last) > 0 {
                                Text("\(Int(lastAvgHR(last))) bpm ø")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                            Text("\(Int(last.calories)) kcal")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        // START button
                        VStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                            Text("START")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        .frame(width: 72, height: 72)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No workouts yet")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        let stats = periodStats  // [Goal, 7 Days, 30 Days, 1 Year]

        return VStack(alignment: .leading, spacing: 0) {
            Text("STATISTICS OVERVIEW")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            // Column headers
            HStack(spacing: 0) {
                Color.clear.frame(width: 72)
                ForEach(Array(statHeaders.enumerated()), id: \.offset) { index, header in
                    Text(header)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(index == 0 ? .green : .white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // Stat rows
            VStack(spacing: 2) {
                statRow(label: "Count", values: stats.map { $0.count }, goalValue: stats[0].count, mode: displayMode)
                statRow(label: "Duration", values: stats.map { $0.duration }, goalValue: stats[0].duration, mode: displayMode)
                statRow(label: "Calories", values: stats.map { $0.calories }, goalValue: stats[0].calories, mode: displayMode)
                statRow(label: "Distance", values: stats.map { $0.distance }, goalValue: stats[0].distance, mode: displayMode)
                statRow(label: "Incline", values: stats.map { $0.elevation }, goalValue: stats[0].elevation, mode: displayMode)
            }

            // Toggle button
            HStack {
                Spacer()
                Button {
                    withAnimation {
                        displayMode = displayMode == .percentage ? .absolute : .percentage
                    }
                } label: {
                    Text(displayMode == .percentage ? "RELATIVE TO REFERENCE" : "ABSOLUTE VALUES")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
            .padding(.top, 10)
        }
    }

    private var statHeaders: [String] {
        ["Goal", "Last\n7 Days", "Last\n30 Days", "Last\nYear"]
    }

    private func statRow(label: String, values: [Double], goalValue: Double, mode: DisplayMode) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 72, alignment: .leading)

            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let result = cellContent(label: label, value: value, goalValue: goalValue, index: index, mode: mode)
                Text(result.text)
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(result.color)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }

    private func cellContent(label: String, value: Double, goalValue: Double, index: Int, mode: DisplayMode) -> (text: String, color: Color) {
        // Goal column (index 0)
        if index == 0 {
            if mode == .percentage {
                return ("100%", .green)
            } else {
                return (goalAbsoluteText(label: label, value: value), .green)
            }
        }

        // Period columns
        if value == 0 && mode == .percentage {
            return ("--", Color(.systemGray4))
        }

        switch mode {
        case .percentage:
            let pct = goalValue > 0 ? (value / goalValue * 100) : 0
            return ("\(Int(pct))%", percentageColor(pct))
        case .absolute:
            return (absoluteText(label: label, value: value), periodColors[index])
        }
    }

    private func goalAbsoluteText(label: String, value: Double) -> String {
        switch label {
        case "Count": return "\(Int(value))"
        case "Duration": return formatDurationShort(value)
        case "Calories": return "\(Int(value))'"
        case "Distance": return String(format: "%.0f", value)
        case "Incline": return "--"
        default: return "\(Int(value))"
        }
    }

    private func absoluteText(label: String, value: Double) -> String {
        switch label {
        case "Count": return "\(Int(value))"
        case "Duration": return formatDurationShort(value)
        case "Calories": return "\(Int(value))"
        case "Distance": return String(format: "%.0f", value)
        case "Incline": return value > 0 ? "\(Int(value))" : "--"
        default: return "\(Int(value))"
        }
    }

    private func percentageColor(_ pct: Double) -> Color {
        if pct < 25 { return .blue }
        if pct < 50 { return Color(red: 0.2, green: 0.5, blue: 1.0) }
        if pct < 80 { return Color(red: 0.3, green: 0.7, blue: 0.4) }
        if pct <= 110 { return .green }
        if pct <= 140 { return Color(red: 0.8, green: 0.7, blue: 0.1) }
        if pct <= 170 { return Color(red: 0.9, green: 0.5, blue: 0.1) }
        return Color(red: 0.9, green: 0.2, blue: 0.1)
    }

    private let periodColors: [Color] = [
        .green,
        Color(red: 0.9, green: 0.6, blue: 0.1),
        Color(red: 0.9, green: 0.4, blue: 0.1),
        Color(red: 0.9, green: 0.2, blue: 0.1)
    ]

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEKLY GOALS")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            let weekWorkouts = thisWeekWorkouts

            ForEach(activeGoals) { goal in
                let current = currentValue(for: goal.type, workouts: weekWorkouts)
                let pct = goal.weeklyTarget > 0 ? min(current / goal.weeklyTarget * 100, 100) : 0

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(goal.type.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(pct))%")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.green)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray4))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(pct >= 100 ? .green : .blue)
                                .frame(width: geo.size.width * min(pct / 100, 1.0))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Data Helpers

    private struct PeriodStat {
        let count: Double
        let duration: Double
        let calories: Double
        let distance: Double
        let elevation: Double
    }

    private var periodStats: [PeriodStat] {
        let now = Date()

        // Goal values (weekly targets from active goals)
        let weekWorkouts = thisWeekWorkouts
        let goalCount = activeGoals.first(where: { $0.type == .workouts })?.weeklyTarget ?? 3
        let goalDuration = (activeGoals.first(where: { $0.type == .duration })?.weeklyTarget ?? 150) * 60 // minutes to seconds
        let goalCalories = activeGoals.first(where: { $0.type == .calories })?.weeklyTarget ?? 2000
        let goalDistance = (activeGoals.first(where: { $0.type == .distance })?.weeklyTarget ?? 20) * 1000 // km to meters
        let goalElevation = activeGoals.first(where: { $0.type == .elevation })?.weeklyTarget ?? 500

        let goal = PeriodStat(
            count: goalCount,
            duration: goalDuration,
            calories: goalCalories,
            distance: goalDistance,
            elevation: goalElevation
        )

        // Period stats
        let periods: [Int] = [7, 30, 365]
        let periodStats = periods.map { days in
            let start = Calendar.current.date(byAdding: .day, value: -days, to: now)!
            let filtered = allWorkouts.filter { $0.startTime >= start }
            return PeriodStat(
                count: Double(filtered.count),
                duration: filtered.reduce(0) { $0 + $1.duration },
                calories: filtered.reduce(0) { $0 + $1.calories },
                distance: filtered.reduce(0) { $0 + $1.distance },
                elevation: filtered.reduce(0) { $0 + $1.elevationGain }
            )
        }

        return [goal] + periodStats
    }

    private var thisWeekWorkouts: [Workout] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return allWorkouts.filter { $0.startTime >= start }
    }

    private func currentValue(for type: GoalType, workouts: [Workout]) -> Double {
        switch type {
        case .workouts: return Double(workouts.count)
        case .duration: return workouts.reduce(0) { $0 + $1.duration } / 60
        case .calories: return workouts.reduce(0) { $0 + $1.calories }
        case .distance: return workouts.reduce(0) { $0 + $1.distance } / 1000
        case .elevation: return workouts.reduce(0) { $0 + $1.elevationGain }
        }
    }

    private func lastAvgHR(_ workout: Workout) -> Double {
        let hr = workout.sensorSamples.filter { $0.type == .heartRate }
        guard !hr.isEmpty else { return 0 }
        return hr.map(\.value).reduce(0, +) / Double(hr.count)
    }

    private func intensityColor(for level: IntensityLevel) -> Color {
        switch level {
        case .easy: return Color(red: 0.6, green: 0.4, blue: 0.8)  // Purple
        case .moderate: return .green
        case .hard: return .orange
        case .veryHard: return .red
        case .maximum: return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "en_US")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func formatDurationShort(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%d'", m)
    }
}
