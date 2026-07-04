import SwiftUI
import SwiftData
import Charts
import CoreLocation

struct WorkoutLiveView: View {
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(LocationManager.self) private var locationManager
    @Environment(SensorManager.self) private var sensorManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let sportType: SportType?
    let intensity: IntensityLevel
    let note: String
    let useGPS: Bool
    let useHR: Bool

    @State private var showMap = false
    @State private var showStopConfirmation = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar for workout views
            HStack(spacing: 0) {
                tabIcon(icon: "timer", index: 0)
                tabIcon(icon: "chart.xyaxis.line", index: 1)
                tabIcon(icon: "waveform.path.ecg", index: 2)
                tabIcon(icon: "bicycle", index: 3)
                tabIcon(icon: "map.fill", index: 4)
            }
            .background(Color(.systemGray6))

            Divider()

            // Content
            TabView(selection: $selectedTab) {
                timerView.tag(0)
                tachometerView.tag(1)
                heartRateView.tag(2)
                sensorView.tag(3)
                mapView.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom controls
            bottomControls
        }
        .background(Color(.systemBackground))
        .navigationTitle("Current Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startWorkout()
        }
        .onChange(of: locationManager.currentLocation) { _, location in
            if let location = location, useGPS {
                recorder.updateFromLocation(location)
            }
        }
        .onChange(of: sensorManager.currentHeartRate) { _, hr in
            if hr > 0, useHR {
                recorder.addHeartRate(Double(hr))
            }
        }
        .onDisappear {
            if recorder.state == .recording || recorder.state == .paused {
                recorder.stop()
                locationManager.stopTracking()
                sensorManager.stopScanning()
            }
        }
        .alert("End Workout?", isPresented: $showStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End", role: .destructive) {
                finishWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout?")
        }
    }

    // MARK: - Tab Icons

    private func tabIcon(icon: String, index: Int) -> some View {
        Button {
            withAnimation { selectedTab = index }
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(selectedTab == index ? .green : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: 16) {
            Spacer()

            // Timer
            Text(formattedTime)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            // Primary metrics
            HStack(spacing: 24) {
                metricBlock(value: String(format: "%.2f", recorder.distance / 1000), unit: "km", label: "Distance")
                metricBlock(value: currentPace, unit: "min/km", label: "Pace")
                metricBlock(value: "\(recorder.currentHeartRate)", unit: "bpm", label: "BPM")
            }

            // Secondary metrics
            HStack(spacing: 24) {
                metricBlock(value: "\(Int(recorder.calories))", unit: "kcal", label: "Calories")
                metricBlock(value: String(format: "%.0f", recorder.elevationGain), unit: "m", label: "Elevation")
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Tachometer View (HR Chart + Zones)

    private var tachometerView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // HR Chart at top
                if !recorder.sensorSamples.isEmpty {
                    hrChart
                        .frame(height: 150)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 150)
                        .overlay {
                            Text("No heart rate data")
                                .foregroundStyle(.secondary)
                        }
                }

                Divider()

                // Time + BPM row
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("Time total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedTime)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Time in zone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(timeInZone)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("BPM")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(recorder.currentHeartRate)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(zoneColor(for: recorder.currentHeartRate))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()

                // Zone distribution bar
                if !recorder.sensorSamples.isEmpty {
                    zoneBar
                }

                // Zone stats
                if !recorder.sensorSamples.isEmpty {
                    zoneStatsRow
                }

                // HR Histogram
                if !recorder.sensorSamples.isEmpty {
                    hrHistogram
                        .frame(height: 100)
                }
            }
        }
    }

    // MARK: - Heart Rate View

    private var heartRateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !recorder.sensorSamples.isEmpty {
                    // HR Stats
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HEART RATE")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            statColumn(label: "Min", value: "\(Int(minHR))", unit: "bpm")
                            statColumn(label: "Max", value: "\(Int(maxHR))", unit: "bpm")
                            statColumn(label: "Avg", value: "\(Int(avgHR))", unit: "bpm ø")
                        }

                        Divider().background(Color.gray.opacity(0.3))

                        HStack(spacing: 0) {
                            statColumn(label: "Target Zone", value: "\(intensity.minHR)..\(intensity.maxHR)", unit: "bpm")
                            statColumn(label: "Time in zone", value: timeInZone, unit: "")
                            statColumn(label: "Avg in zone", value: "\(Int(avgHR))", unit: "bpm")
                        }
                    }
                    .padding()

                    // Zone bar
                    zoneBar

                    // HR Chart
                    hrChart
                        .frame(height: 150)

                    // Histogram
                    hrHistogram
                        .frame(height: 100)
                } else {
                    ContentUnavailableView(
                        "No Heart Rate Data",
                        systemImage: "heart.slash",
                        description: Text("Connect a heart rate sensor to see data here.")
                    )
                }
            }
        }
    }

    // MARK: - Sensor View

    private var sensorView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Cadence, speed, and temperature data will appear here when connected sensors provide them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()

            Spacer()
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        MapTrackView(
            trackPoints: recorder.trackPoints.map { tp in
                CLLocationCoordinate2D(latitude: tp.latitude, longitude: tp.longitude)
            },
            currentLocation: locationManager.currentLocation?.coordinate
        )
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 24) {
            if recorder.state == .recording {
                Button {
                    recorder.pause()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .frame(width: 56, height: 56)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            } else if recorder.state == .paused {
                Button {
                    recorder.resume()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .frame(width: 56, height: 56)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }

            Button {
                showStopConfirmation = true
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - HR Chart

    private var hrChart: some View {
        let hrSamples = recorder.sensorSamples
            .filter { $0.unit == "bpm" }
            .enumerated()
            .map { (offset, sample) in
                HRDataPoint(index: offset, value: sample.value, timestamp: sample.timestamp)
            }

        return Chart(hrSamples) { point in
            LineMark(
                x: .value("Time", point.index),
                y: .value("BPM", point.value)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)

            // Zone color overlay
            AreaMark(
                x: .value("Time", point.index),
                y: .value("BPM", point.value)
            )
            .foregroundStyle(zoneColor(for: Int(point.value)).opacity(0.3))
            .interpolationMethod(.catmullRom)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let hr = value.as(Int.self) {
                        Text("\(hr)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - HR Histogram

    private var hrHistogram: some View {
        let hrSamples = recorder.sensorSamples.filter { $0.unit == "bpm" }
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
        .background(Color(.systemBackground))
    }

    // MARK: - Zone Bar

    private var zoneBar: some View {
        let hrSamples = recorder.sensorSamples.filter { $0.unit == "bpm" }
        let total = max(1, hrSamples.count)

        let belowZone = hrSamples.filter { Int($0.value) < intensity.minHR }.count
        let inZone = hrSamples.filter { Int($0.value) >= intensity.minHR && Int($0.value) <= intensity.maxHR }.count
        let aboveZone = hrSamples.filter { Int($0.value) > intensity.maxHR }.count

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

    // MARK: - Zone Stats Row

    private var zoneStatsRow: some View {
        let hrSamples = recorder.sensorSamples.filter { $0.unit == "bpm" }
        let values = hrSamples.map(\.value)

        return HStack(spacing: 0) {
            statColumn(label: "Min", value: "\(Int(values.min() ?? 0))", unit: "bpm")
            statColumn(label: "Max", value: "\(Int(values.max() ?? 0))", unit: "bpm")
            statColumn(label: "Avg total", value: "\(Int(values.reduce(0, +) / Double(max(1, values.count))))", unit: "bpm")
            statColumn(label: "Avg in zone", value: "\(Int(avgHR))", unit: "bpm")
        }
        .padding()
    }

    // MARK: - Helpers

    private func statColumn(label: String, value: String, unit: String) -> some View {
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

    private func metricBlock(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.gray)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func zoneColor(for hr: Int) -> Color {
        if hr < intensity.minHR { return .blue }
        if hr <= intensity.maxHR { return .green }
        if hr <= intensity.maxHR + 20 { return Color(.systemYellow) }
        return .red
    }

    private func zoneColor(for hr: Double) -> Color {
        zoneColor(for: Int(hr))
    }

    private var formattedTime: String {
        let total = Int(recorder.elapsedSeconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private var currentPace: String {
        guard recorder.distance > 0, recorder.elapsedSeconds > 0 else { return "--:--" }
        let paceSeconds = recorder.elapsedSeconds / (recorder.distance / 1000)
        let m = Int(paceSeconds) / 60
        let s = Int(paceSeconds) % 60
        return String(format: "%d:%02d", m, s)
    }

    private var timeInZone: String {
        let hrSamples = recorder.sensorSamples.filter { $0.unit == "bpm" }
        let inZone = hrSamples.filter { Int($0.value) >= intensity.minHR && Int($0.value) <= intensity.maxHR }
        let seconds = Double(inZone.count)
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var minHR: Double {
        recorder.sensorSamples.filter { $0.unit == "bpm" }.map(\.value).min() ?? 0
    }

    private var maxHR: Double {
        recorder.sensorSamples.filter { $0.unit == "bpm" }.map(\.value).max() ?? 0
    }

    private var avgHR: Double {
        let samples = recorder.sensorSamples.filter { $0.unit == "bpm" }
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.value).reduce(0, +) / Double(samples.count)
    }

    private func startWorkout() {
        recorder.start()
        if useGPS {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startTracking()
        }
        if useHR {
            sensorManager.startScanning()
        }
    }

    private func finishWorkout() {
        let endTime = Date()
        let duration = recorder.elapsedSeconds

        let workout = Workout(
            sportType: sportType,
            startTime: endTime.addingTimeInterval(-duration),
            endTime: endTime,
            duration: duration,
            distance: recorder.distance,
            calories: recorder.calories,
            elevationGain: recorder.elevationGain,
            note: note.isEmpty ? nil : note,
            intensity: intensity,
            isManual: false
        )

        for tpData in recorder.trackPoints {
            let tp = TrackPoint(
                timestamp: tpData.timestamp,
                latitude: tpData.latitude,
                longitude: tpData.longitude,
                altitude: tpData.altitude,
                speed: tpData.speed
            )
            tp.workout = workout
            workout.trackPoints.append(tp)
        }

        for sData in recorder.sensorSamples {
            let sample = SensorSample(
                timestamp: sData.timestamp,
                type: .heartRate,
                value: sData.value,
                unit: sData.unit
            )
            sample.workout = workout
            workout.sensorSamples.append(sample)
        }

        modelContext.insert(workout)
        try? modelContext.save()

        recorder.stop()
        locationManager.stopTracking()
        sensorManager.stopScanning()

        dismiss()
    }
}

// MARK: - Data Models

struct HRDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
    let timestamp: Date
}

struct HRBucket: Identifiable {
    let id = UUID()
    let range: Int
    let count: Int
}
