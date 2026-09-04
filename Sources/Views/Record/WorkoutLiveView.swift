import SwiftUI
import SwiftData
import Charts
import CoreLocation
import UIKit

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
    @State private var showSaveError = false

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
        .navigationTitle("Record.CurrentWorkout".localized())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
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
            UIApplication.shared.isIdleTimerDisabled = false
            if recorder.state == .recording || recorder.state == .paused {
                recorder.stop()
                locationManager.stopTracking()
                sensorManager.stopScanning()
            }
        }
        .alert("Record.EndWorkout".localized(), isPresented: $showStopConfirmation) {
            Button("Cancel".localized(), role: .cancel) { }
            Button("Live.End".localized(), role: .destructive) {
                finishWorkout()
            }
        } message: {
            Text("Record.EndWorkoutMessage".localized())
        }
        .alert("Record.SaveFailed".localized(), isPresented: $showSaveError) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Record.SaveFailedMessage".localized())
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
        ScrollView {
            VStack(spacing: 12) {
                Spacer()

                // Timer
                Text(formattedTime)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // GPS Status + Altitude
                if useGPS {
                    gpsStatusView
                }

                // Primary metrics - Row 1
                HStack(spacing: 0) {
                    metricCell(value: String(format: "%.2f", recorder.distance / 1000), unit: "Timer.km".localized(), label: "Timer.Distance".localized())
                    metricCell(value: currentPace, unit: "Timer.min/km".localized(), label: "Timer.Pace".localized())
                    metricCell(value: "\(recorder.currentHeartRate)", unit: "Timer.bpm".localized(), label: "Timer.BPM".localized())
                }

                Divider().background(Color.gray.opacity(0.3))

                // Secondary metrics - Row 2
                HStack(spacing: 0) {
                    metricCell(value: "\(Int(recorder.calories))", unit: "Timer.kcal".localized(), label: "Timer.Calories".localized())
                    metricCell(value: String(format: "%.0f", recorder.elevationGain), unit: "Timer.m".localized(), label: "Timer.Elevation".localized())
                    metricCell(value: currentSpeed, unit: "Timer.kmh".localized(), label: "Timer.Speed".localized())
                }

                // GPS Data (Android shows lat/long/altitude)
                if useGPS, let location = locationManager.currentLocation {
                    Divider().background(Color.gray.opacity(0.3))

                    VStack(spacing: 4) {
                        Text(gpsCoordinatesText(location))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text("Live.Alt".localized() + " \(Int(location.altitude))m | \(gpsStatusText)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Calorie breakdown (Android shows cal/min and cal/hour)
                if recorder.calories > 0 && recorder.elapsedSeconds > 0 {
                    HStack(spacing: 16) {
                        Text("\(caloriesPerMinute, specifier: "%.1f") \("Timer.kcalmin".localized())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(caloriesPerHour, specifier: "%.0f") \("Timer.kcalh".localized())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    private var currentSpeed: String {
        guard let location = locationManager.currentLocation, location.speed >= 0 else {
            return "--.-"
        }
        return String(format: "%.1f", location.speed * 3.6)
    }

    private var caloriesPerMinute: Double {
        guard recorder.elapsedSeconds > 60 else { return 0 }
        return recorder.calories / (recorder.elapsedSeconds / 60.0)
    }

    private var caloriesPerHour: Double {
        caloriesPerMinute * 60
    }

    private func gpsCoordinatesText(_ location: CLLocation) -> String {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let latDir = lat >= 0 ? "N" : "S"
        let lonDir = lon >= 0 ? "E" : "W"
        return String(format: "%.6f°%@ %.6f°%@", abs(lat), latDir, abs(lon), lonDir)
    }

    private var gpsStatusView: some View {
        HStack(spacing: 16) {
            Image(systemName: "location.fill")
                .foregroundStyle(gpsAccuracyColor)
            Text(gpsStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var gpsStatusText: String {
        guard let location = locationManager.currentLocation else {
            return "GPS.Searching".localized()
        }
        let accuracy = location.horizontalAccuracy
        if accuracy < 0 {
            return "GPS.Invalid".localized()
        } else if accuracy < 5 {
            return "GPS.Excellent".localized() + " (\(Int(accuracy))m)"
        } else if accuracy < 10 {
            return "GPS.Good".localized() + " (\(Int(accuracy))m)"
        } else if accuracy < 30 {
            return "GPS.Fair".localized() + " (\(Int(accuracy))m)"
        } else {
            return "GPS.Poor".localized() + " (\(Int(accuracy))m)"
        }
    }

    private var gpsAccuracyColor: Color {
        guard let location = locationManager.currentLocation else { return .gray }
        let accuracy = location.horizontalAccuracy
        if accuracy < 0 { return .red }
        if accuracy < 5 { return .green }
        if accuracy < 10 { return .yellow }
        if accuracy < 30 { return .orange }
        return .red
    }

    private func metricCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
                            Text("Live.NoHeartRateData".localized())
                                .foregroundStyle(.secondary)
                        }
                }

                Divider()

                // Time + BPM row
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("HR.TimeTotal".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedTime)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("HR.TimeInZone".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(timeInZone)
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        Text("Timer.BPM".localized())
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
                        Text("Detail.HeartRate".localized())
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        HStack(spacing: 0) {
                            statColumn(label: "HR.Min".localized(), value: "\(Int(minHR))", unit: "Timer.bpm".localized())
                            statColumn(label: "HR.Max".localized(), value: "\(Int(maxHR))", unit: "Timer.bpm".localized())
                            statColumn(label: "HR.Avg".localized(), value: "\(Int(avgHR))", unit: "History.BpmAvg".localized())
                        }

                        Divider().background(Color.gray.opacity(0.3))

                        HStack(spacing: 0) {
                            statColumn(label: "Detail.TargetZone".localized(), value: "\(intensity.minHR)..\(intensity.maxHR)", unit: "Timer.bpm".localized())
                            statColumn(label: "Detail.TimeInZone".localized(), value: timeInZone, unit: "")
                            statColumn(label: "Detail.AvgInZone".localized(), value: "\(Int(avgHR))", unit: "Timer.bpm".localized())
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
                        "HR.NoData".localized(),
                        systemImage: "heart.slash",
                        description: Text("HR.ConnectSensor".localized())
                    )
                }
            }
        }
    }

    // MARK: - Sensor View (Diagnosis)

    private var sensorView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Bluetooth Status
                diagnosisSection(title: "Bluetooth", icon: "antenna.radiowaves.left.and.right") {
                    diagnosisRow(label: "Status", value: sensorManager.bluetoothState, color: bluetoothColor)
                    if let error = sensorManager.errorMessage {
                        diagnosisRow(label: "Error", value: error, color: .red)
                    }
                }

                // Heart Rate Sensor
                diagnosisSection(title: "Heart Rate Sensor", icon: "heart.fill") {
                    diagnosisRow(label: "Connection", value: sensorManager.isConnected ? "Connected" : "Disconnected", color: sensorManager.isConnected ? .green : .red)
                    diagnosisRow(label: "Device", value: sensorManager.deviceName.isEmpty ? "None" : sensorManager.deviceName)
                    diagnosisRow(label: "Battery", value: sensorManager.batteryLevel >= 0 ? "\(sensorManager.batteryLevel)%" : "N/A", color: batteryColor)
                    diagnosisRow(label: "Scanning", value: sensorManager.isScanning ? "Yes" : "No")
                    diagnosisRow(label: "Reconnection Attempts", value: "\(sensorManager.reconnectionAttempts)")
                    if let lastDisconnect = sensorManager.lastDisconnectionTime {
                        diagnosisRow(label: "Last Disconnect", value: lastDisconnect.formatted(date: .omitted, time: .shortened))
                    }
                    if sensorManager.isConnected {
                        diagnosisRow(label: "Current HR", value: "\(sensorManager.currentHeartRate) bpm")
                    }
                    if !sensorManager.isConnected {
                        Button("Reconnect") {
                            sensorManager.manualReconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }

                // GPS Status
                if useGPS {
                    diagnosisSection(title: "GPS", icon: "location.fill") {
                        diagnosisRow(label: "Status", value: locationManager.isTrackingLocation ? "Tracking" : "Off", color: locationManager.isTrackingLocation ? .green : .red)
                        diagnosisRow(label: "Auth", value: authorizationStatusText)
                        if let location = locationManager.currentLocation {
                            diagnosisRow(label: "Position", value: gpsCoordinatesText(location), color: .primary)
                            diagnosisRow(label: "Accuracy", value: "\(Int(location.horizontalAccuracy))m", color: gpsAccuracyColor)
                            diagnosisRow(label: "Altitude", value: location.altitude >= 0 ? "\(Int(location.altitude))m" : "N/A")
                            diagnosisRow(label: "Speed", value: location.speed >= 0 ? String(format: "%.1f km/h", location.speed * 3.6) : "N/A")
                            diagnosisRow(label: "Altitude (GPS)", value: String(format: "%.0fm", location.altitude))
                        }
                    }
                }

                // Recording Status
                diagnosisSection(title: "Recording", icon: "record.circle") {
                    diagnosisRow(label: "State", value: stateText, color: stateColor)
                    diagnosisRow(label: "Duration", value: formattedTime)
                    diagnosisRow(label: "Track Points", value: "\(recorder.trackPoints.count)")
                    diagnosisRow(label: "HR Samples", value: "\(recorder.sensorSamples.count)")
                }
            }
            .padding()
        }
    }

    private var bluetoothColor: Color {
        switch sensorManager.bluetoothState {
        case "Powered On": return .green
        case "Powered Off": return .red
        default: return .orange
        }
    }

    private var batteryColor: Color {
        let level = sensorManager.batteryLevel
        if level < 0 { return .gray }
        if level < 20 { return .red }
        if level < 50 { return .orange }
        return .green
    }

    private var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    private var stateText: String {
        switch recorder.state {
        case .idle: return "Idle"
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .completed: return "Completed"
        }
    }

    private var stateColor: Color {
        switch recorder.state {
        case .idle: return .gray
        case .recording: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }

    @ViewBuilder
    private func diagnosisSection(title: String, icon: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func diagnosisRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
        .font(.subheadline)
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

        return GeometryReader { geo in
            HStack(spacing: 0) {
                if belowPct > 0 {
                    Text("\(Int(belowPct))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: geo.size.width * belowPct / 100)
                        .background(.blue)
                }
                if inPct > 0 {
                    Text("\(Int(inPct))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: geo.size.width * inPct / 100)
                        .background(.green)
                }
                if abovePct > 0 {
                    Text("\(Int(abovePct))%")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: geo.size.width * abovePct / 100)
                        .background(Color(.systemYellow))
                }
            }
            .frame(height: 28)
        }
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
        var weight: Double?
        var age: Int?
        var gender: Gender?

        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? modelContext.fetch(descriptor).first {
            weight = profile.weight
            gender = profile.gender
            if let birthDate = profile.birthDate {
                let calendar = Calendar.current
                let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
                age = ageComponents.year
            }
        }

        recorder.start(weight: weight, age: age, gender: gender)
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
        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
            showSaveError = true
            return
        }

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
