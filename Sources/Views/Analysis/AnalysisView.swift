import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]

    @State private var selectedPeriod = "Analysis.7Days"
    @State private var selectedTab = 0

    private let periodKeys = ["Analysis.7Days", "Analysis.30Days", "Analysis.Year", "Analysis.All"]

    private var filteredWorkouts: [Workout] {
        let now = Date()
        switch selectedPeriod {
        case "Analysis.7Days":
            let start = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return allWorkouts.filter { $0.startTime >= start }
        case "Analysis.30Days":
            let start = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return allWorkouts.filter { $0.startTime >= start }
        case "Analysis.Year":
            let start = Calendar.current.date(byAdding: .year, value: -1, to: now)!
            return allWorkouts.filter { $0.startTime >= start }
        default:
            return allWorkouts
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Period picker
            HStack(spacing: 0) {
                ForEach(periodKeys, id: \.self) { periodKey in
                    Button {
                        withAnimation { selectedPeriod = periodKey }
                    } label: {
                        Text(periodKey.localized())
                            .font(.caption.bold())
                            .foregroundStyle(selectedPeriod == periodKey ? .green : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedPeriod == periodKey ? Color(.systemGray5) : Color.clear)
                    }
                }
            }
            .background(Color(.systemGray6))

            Divider()

            // Content
            if filteredWorkouts.isEmpty {
                ContentUnavailableView(
                    "Analysis.NoData".localized(),
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text("Analysis.RecordToSee".localized())
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Summary stats
                        summarySection

                        Divider().background(Color.gray.opacity(0.3))

                        // Workout count chart
                        if filteredWorkouts.count >= 2 {
                            chartSection(title: "Analysis.WorkoutFrequency".localized()) {
                                Chart {
                                    ForEach(filteredWorkouts.suffix(20)) { workout in
                                        BarMark(
                                            x: .value("Date", workout.startTime, unit: .day),
                                            y: .value("Count", 1)
                                        )
                                        .foregroundStyle(.green)
                                    }
                                }
                                .frame(height: 120)
                            }
                        }

                        // Distance chart
                        if filteredWorkouts.count >= 2 {
                            Divider().background(Color.gray.opacity(0.3))
                            chartSection(title: "Analysis.DistanceOverTime".localized()) {
                                Chart {
                                    ForEach(filteredWorkouts.suffix(20)) { workout in
                                        LineMark(
                                            x: .value("Date", workout.startTime),
                                            y: .value("Distance", workout.distance / 1000)
                                        )
                                        .foregroundStyle(.green)
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 150)
                            }
                        }

                        // HR chart
                        let allHR = filteredWorkouts.flatMap { $0.sensorSamples.filter { $0.type == .heartRate } }
                        if allHR.count >= 2 {
                            Divider().background(Color.gray.opacity(0.3))
                            chartSection(title: "Heart Rate") {
                                Chart {
                                    ForEach(allHR.prefix(200)) { sample in
                                        PointMark(
                                            x: .value("Time", sample.timestamp),
                                            y: .value("BPM", sample.value)
                                        )
                                        .foregroundStyle(.green.opacity(0.6))
                                    }
                                }
                                .frame(height: 150)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Analysis.Title".localized())
    }

    // MARK: - Summary

    private var summarySection: some View {
        let totalDistance = filteredWorkouts.reduce(0) { $0 + $1.distance }
        let totalDuration = filteredWorkouts.reduce(0) { $0 + $1.duration }
        let totalCalories = filteredWorkouts.reduce(0) { $0 + $1.calories }
        let totalElevation = filteredWorkouts.reduce(0) { $0 + $1.elevationGain }

        return VStack(spacing: 12) {
            HStack(spacing: 0) {
                statCell(value: "\(filteredWorkouts.count)", label: "Analysis.Workouts".localized())
                statCell(value: String(format: "%.1f", totalDistance / 1000), label: "Analysis.km".localized())
                statCell(value: formatDuration(totalDuration), label: "Analysis.Duration".localized())
            }
            HStack(spacing: 0) {
                statCell(value: "\(Int(totalCalories))", label: "Analysis.Calories".localized())
                statCell(value: "\(Int(totalElevation))", label: "m")
                statCell(value: "", label: "")
            }
        }
        .padding()
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart Section

    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            content()
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }
}
