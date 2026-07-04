import SwiftUI
import SwiftData
import Charts
import CoreLocation

struct WorkoutDetailView: View {
    let workout: Workout

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var isEditing = false
    @State private var selectedTab = 0

    @State private var editNote: String = ""
    @State private var editIntensity: IntensityLevel = .moderate

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton(title: "FACTS", index: 0)
                tabButton(title: "CHARTS", index: 1)
                tabButton(title: "HEART RATE", index: 2)
            }
            .background(Color(.systemGray6))

            Divider()

            // Content
            TabView(selection: $selectedTab) {
                factsTab.tag(0)
                chartsTab.tag(1)
                heartRateTab.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemBackground))
        .navigationTitle(workout.sportType?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.green)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .sheet(isPresented: $showShareSheet) {
            if let gpxData = GPXManager.exportWorkout(workout) {
                ShareSheet(items: [gpxData])
            }
        }
        .alert("Delete Workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(workout)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Tab Button

    private func tabButton(title: String, index: Int) -> some View {
        Button {
            withAnimation { selectedTab = index }
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(selectedTab == index ? .green : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(selectedTab == index ? Color(.systemGray5) : Color.clear)
        }
    }

    // MARK: - Facts Tab

    private var factsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Workout info
                HStack {
                    if let sport = workout.sportType {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: sport.color) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(sport.abbreviation)
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                    }
                    VStack(alignment: .leading) {
                        Text(workout.startTime, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(formatDuration(workout.duration))")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if workout.isManual {
                        Text("Manual")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Divider().background(Color.gray.opacity(0.3))

                // Heart Rate section
                if !heartRateSamples.isEmpty {
                    Text("HEART RATE")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(spacing: 0) {
                        factColumn(label: "Min", value: "\(Int(minHR))", unit: "bpm")
                        factColumn(label: "Max", value: "\(Int(maxHR))", unit: "bpm")
                        factColumn(label: "Avg", value: "\(Int(avgHR))", unit: "bpm ø")
                    }

                    HStack(spacing: 0) {
                        factColumn(label: "Target Zone", value: "\(workout.intensity.minHR)..\(workout.intensity.maxHR)", unit: "bpm")
                        factColumn(label: "Time in zone", value: timeInZone, unit: "")
                        factColumn(label: "Avg in zone", value: "\(Int(avgHR))", unit: "bpm")
                    }

                    // Zone bar
                    zoneBar
                }

                Divider().background(Color.gray.opacity(0.3))

                // Key metrics
                Text("METRICS")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    metricItem(value: formattedDuration, label: "Duration", icon: "clock")
                    metricItem(value: String(format: "%.2f km", workout.distance / 1000), label: "Distance", icon: "ruler")
                    metricItem(value: "\(Int(workout.calories))", label: "Calories", icon: "flame")
                    metricItem(value: String(format: "%.0f m", workout.elevationGain), label: "Elevation", icon: "mountain.2")
                    if workout.distance > 0 && workout.duration > 0 {
                        metricItem(value: currentPace, label: "Avg Pace", icon: "speedometer")
                    }
                }

                // Map track
                if workout.trackPoints.count >= 2 {
                    Divider().background(Color.gray.opacity(0.3))
                    Text("TRACK")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    StaticMapTrackView(
                        trackPoints: workout.trackPoints.map {
                            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                        }
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Notes
                if let note = workout.note, !note.isEmpty {
                    Divider().background(Color.gray.opacity(0.3))
                    Text("NOTES")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(note)
                        .foregroundStyle(.white)
                }

                // Actions
                Divider().background(Color.gray.opacity(0.3))
                if !workout.isManual {
                    Button {
                        exportGPX()
                    } label: {
                        Label("Export GPX", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Workout", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    // MARK: - Charts Tab

    private var chartsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // HR chart
                if !heartRateSamples.isEmpty {
                    chartSection(title: "Heart Rate") {
                        Chart(heartRateSamples) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("BPM", sample.value)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("BPM", sample.value)
                            )
                            .foregroundStyle(.green.opacity(0.2))
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 150)
                    }
                }

                // Pace chart
                if workout.trackPoints.count >= 2 {
                    chartSection(title: "Pace") {
                        Chart(Array(paceData.enumerated()), id: \.offset) { index, pace in
                            LineMark(
                                x: .value("Point", index),
                                y: .value("Pace", pace)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 150)
                    }
                }

                // Elevation chart
                if workout.trackPoints.contains(where: { $0.altitude != nil }) {
                    chartSection(title: "Altitude") {
                        Chart(workout.trackPoints.enumerated().filter { $0.element.altitude != nil }, id: \.offset) { index, point in
                            LineMark(
                                x: .value("Point", index),
                                y: .value("Altitude", point.altitude!)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 150)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Heart Rate Tab

    private var heartRateTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !heartRateSamples.isEmpty {
                    // HR Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEART RATE")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            factColumn(label: "Min", value: "\(Int(minHR))", unit: "bpm")
                            factColumn(label: "Max", value: "\(Int(maxHR))", unit: "bpm")
                            factColumn(label: "Avg", value: "\(Int(avgHR))", unit: "bpm ø")
                        }

                        Divider().background(Color.gray.opacity(0.3))

                        HStack(spacing: 0) {
                            factColumn(label: "Target Zone", value: "\(workout.intensity.minHR)..\(workout.intensity.maxHR)", unit: "bpm")
                            factColumn(label: "Time in zone", value: timeInZone, unit: "")
                            factColumn(label: "Avg in zone", value: "\(Int(avgHR))", unit: "bpm")
                        }
                    }

                    // Zone bar
                    zoneBar

                    // HR Chart
                    Chart(heartRateSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("BPM", sample.value)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 150)

                    // Histogram
                    hrHistogram
                        .frame(height: 100)
                } else {
                    ContentUnavailableView(
                        "No Heart Rate Data",
                        systemImage: "heart.slash",
                        description: Text("No heart rate data recorded for this workout.")
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private func chartSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func factColumn(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func metricItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.green)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Zone Bar

    private var zoneBar: some View {
        let total = max(1, heartRateSamples.count)
        let belowZone = heartRateSamples.filter { Int($0.value) < workout.intensity.minHR }.count
        let inZone = heartRateSamples.filter { Int($0.value) >= workout.intensity.minHR && Int($0.value) <= workout.intensity.maxHR }.count
        let aboveZone = heartRateSamples.filter { Int($0.value) > workout.intensity.maxHR }.count

        let belowPct = Double(belowZone) / Double(total) * 100
        let inPct = Double(inZone) / Double(total) * 100
        let abovePct = Double(aboveZone) / Double(total) * 100

        return HStack(spacing: 0) {
            if belowPct > 0 {
                Text("\(Int(belowPct))%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: UIScreen.main.bounds.width * belowPct / 100)
                    .background(.blue)
            }
            if inPct > 0 {
                Text("\(Int(inPct))%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: UIScreen.main.bounds.width * inPct / 100)
                    .background(.green)
            }
            if abovePct > 0 {
                Text("\(Int(abovePct))%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: UIScreen.main.bounds.width * abovePct / 100)
                    .background(Color(.systemYellow))
            }
        }
        .frame(height: 28)
    }

    // MARK: - HR Histogram

    private var hrHistogram: some View {
        let hrSamples = heartRateSamples
        let minVal = max(60, Int(hrSamples.map(\.value).min() ?? 60) - 10)
        let maxVal = Int(hrSamples.map(\.value).max() ?? 180) + 10
        let bucketSize = max(1, (maxVal - minVal) / 20)

        var buckets: [Int: Int] = [:]
        for sample in hrSamples {
            let bucket = (Int(sample.value) - minVal) / bucketSize
            buckets[bucket, default: 0] += 1
        }

        let histogramData = (0..<(maxVal - minVal) / bucketSize).map { i in
            HRBucket(range: i * bucketSize + minVal, count: buckets[i] ?? 0)
        }

        return Chart(histogramData) { bucket in
            BarMark(
                x: .value("HR", bucket.range),
                y: .value("Count", bucket.count)
            )
            .foregroundStyle(zoneColor(for: bucket.range))
        }
        .chartXAxis(.hidden)
    }

    private func zoneColor(for hr: Int) -> Color {
        if hr < workout.intensity.minHR { return .blue }
        if hr <= workout.intensity.maxHR { return .green }
        if hr <= workout.intensity.maxHR + 20 { return Color(.systemYellow) }
        return .red
    }

    // MARK: - Computed

    private var heartRateSamples: [SensorSample] {
        workout.sensorSamples
            .filter { $0.type == .heartRate }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var minHR: Double {
        heartRateSamples.map(\.value).min() ?? 0
    }

    private var maxHR: Double {
        heartRateSamples.map(\.value).max() ?? 0
    }

    private var avgHR: Double {
        guard !heartRateSamples.isEmpty else { return 0 }
        return heartRateSamples.map(\.value).reduce(0, +) / Double(heartRateSamples.count)
    }

    private var timeInZone: String {
        let inZone = heartRateSamples.filter {
            Int($0.value) >= workout.intensity.minHR && Int($0.value) <= workout.intensity.maxHR
        }
        let seconds = Double(inZone.count)
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var paceData: [Double] {
        guard workout.trackPoints.count >= 2 else { return [] }
        var paces: [Double] = []
        for i in 1..<workout.trackPoints.count {
            let prev = workout.trackPoints[i - 1]
            let curr = workout.trackPoints[i]
            let dist = haversineDistance(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )
            let time = curr.timestamp.timeIntervalSince(prev.timestamp)
            if dist > 0, time > 0 {
                paces.append(time / (dist / 1000))
            }
        }
        return paces
    }

    private var formattedDuration: String {
        let total = Int(workout.duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private var currentPace: String {
        guard workout.distance > 0, workout.duration > 0 else { return "--:--" }
        let paceSeconds = workout.duration / (workout.distance / 1000)
        let m = Int(paceSeconds) / 60
        let s = Int(paceSeconds) % 60
        return String(format: "%d:%02d min/km", m, s)
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

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private func exportGPX() {
        showShareSheet = true
    }

    // MARK: - Edit Sheet

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Notes") {
                    TextEditor(text: $editNote)
                        .frame(minHeight: 60)
                }
                Section("Intensity") {
                    Picker("Intensity", selection: $editIntensity) {
                        ForEach(IntensityLevel.allCases, id: \.self) { level in
                            Text(level.name).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        workout.note = editNote.isEmpty ? nil : editNote
                        workout.intensity = editIntensity
                        try? modelContext.save()
                        isEditing = false
                    }
                }
            }
            .onAppear {
                editNote = workout.note ?? ""
                editIntensity = workout.intensity
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        guard length == 6 || length == 8 else { return nil }

        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1.0
        } else {
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
