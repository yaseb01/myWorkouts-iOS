import SwiftUI
import SwiftData

struct WorkoutSetupView: View {
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(LocationManager.self) private var locationManager
    @Environment(SensorManager.self) private var sensorManager
    @Query(sort: \SportType.name) private var sportTypes: [SportType]

    @State private var selectedSportType: SportType?
    @State private var intensity: IntensityLevel = .moderate
    @State private var useGPS = true
    @State private var useHeartRate = false
    @State private var note: String = ""
    @State private var showLiveWorkout = false
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar (matching Android)
            HStack(spacing: 0) {
                tabButton(icon: "slider.horizontal.3", index: 0)
                tabButton(icon: "location.fill", index: 1)
                tabButton(icon: "antenna.radiowaves.left.and.right", index: 2)
                tabButton(icon: "waveform.path.ecg", index: 3)
            }
            .background(Color(.systemGray6))

            Divider()

            // Content
            TabView(selection: $selectedTab) {
                settingsTab.tag(0)
                gpsTab.tag(1)
                bluetoothTab.tag(2)
                sensorTab.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Bottom buttons
            HStack(spacing: 16) {
                Button("Record.CANCEL".localized()) {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Button {
                    showLiveWorkout = true
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.green)
                        Text("Record.START".localized())
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(recorder.state == .recording)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Record.WorkoutSetup".localized())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showLiveWorkout) {
            WorkoutLiveView(
                sportType: selectedSportType,
                intensity: intensity,
                note: note,
                useGPS: useGPS,
                useHR: useHeartRate
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkLocationPermission()
        }
    }

    // MARK: - Tabs

    private func tabButton(icon: String, index: Int) -> some View {
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

    // MARK: - Settings Tab

    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Workout Type
                HStack {
                    Text("Setup.WorkoutType".localized())
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $selectedSportType) {
                        Text("Setup.None".localized()).tag(nil as SportType?)
                        ForEach(sportTypes) { sport in
                            Text(sport.name).tag(sport as SportType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.green)
                }
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Level
                HStack {
                    Text("Setup.Level".localized())
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $intensity) {
                        ForEach(IntensityLevel.allCases, id: \.self) { level in
                            Text("\(level.name) (\(level.rawValue * 20)% - \((level.rawValue + 1) * 20)%)").tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.green)
                }
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Note
                VStack(alignment: .leading, spacing: 4) {
                    Text("Record.Note".localized())
                        .foregroundStyle(.secondary)
                    TextField("Setup.OptionalNote".localized(), text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
    }

    // MARK: - GPS Tab

    private var gpsTab: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $useGPS) {
                Label("Setup.TrackRoute".localized(), systemImage: "map")
                    .foregroundStyle(.white)
            }
            .tint(.green)
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if useGPS {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                    Text("Setup.GPSEnabled".localized())
                        .foregroundStyle(.white)
                    Spacer()
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Setup.Enable".localized()) {
                            locationManager.requestWhenInUseAuthorization()
                        }
                        .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Bluetooth Tab

    private var bluetoothTab: some View {
        VStack(spacing: 16) {
            Toggle(isOn: $useHeartRate) {
                Label("Setup.BluetoothLE".localized(), systemImage: "heart.fill")
                    .foregroundStyle(.white)
            }
            .tint(.green)
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if useHeartRate {
                if sensorManager.isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading) {
                            Text(sensorManager.deviceName)
                                .foregroundStyle(.white)
                            if sensorManager.batteryLevel >= 0 {
                                Text("Sensor.Battery".localized() + ": \(sensorManager.batteryLevel)%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Setup.Disconnect".localized()) {
                            sensorManager.disconnect()
                        }
                        .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button {
                        sensorManager.startScanning()
                    } label: {
                        HStack {
                            if sensorManager.isScanning {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(sensorManager.isScanning ? "Sensor.Scanning".localized() : "Setup.ScanSensors".localized())
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Sensor Tab (HR Chart)

    private var sensorTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                if sensorManager.isConnected && sensorManager.currentHeartRate > 0 {
                    // Live HR chart
                    liveHRChart
                } else {
                    // Demo/sample HR chart
                    sampleHRChart
                }
            }
        }
    }

    private var liveHRChart: some View {
        VStack(spacing: 0) {
            // HR Line Chart (simulated with last readings)
            Text("Timer.bpm".localized())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            // Simulated chart area
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 180)
                .overlay {
                    VStack {
                        Text(String(format: "Setup.LiveHR".localized(), sensorManager.currentHeartRate))
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(.green)
                        Text(String(format: "Setup.ConnectedTo".localized(), sensorManager.deviceName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

            // Zone bar
            zoneBarPreview

            // Zone stats
            HStack(spacing: 0) {
                zoneStat(label: "HR.Min".localized(), value: "\(sensorManager.currentHeartRate - 20)")
                zoneStat(label: "HR.Max".localized(), value: "\(sensorManager.currentHeartRate + 15)")
                zoneStat(label: "HR.Avg".localized(), value: "\(sensorManager.currentHeartRate)")
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private var sampleHRChart: some View {
        VStack(spacing: 0) {
            // Simulated HR chart with sample data
            ZStack {
                // Chart background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)

                // Simulated line chart overlay
                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(0..<60, id: \.self) { i in
                            let height = CGFloat.random(in: 40...160)
                            Rectangle()
                                .fill(zoneColor(for: Int.random(in: 80...170)))
                                .frame(width: 3, height: height)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 8)

                    // Y-axis labels
                    HStack {
                        Text("80")
                        Spacer()
                        Text("100")
                        Spacer()
                        Text("120")
                        Spacer()
                        Text("140")
                        Spacer()
                        Text("160")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
                }
            }
            .padding(.horizontal)

            // "bpm" watermark
            Text("bpm")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(.systemGray4).opacity(0.3))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, -80)

            // Zone distribution bar
            HStack(spacing: 0) {
                Text("44%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.3, green: 0.3, blue: 0.8))
                Text("37%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(.green)
                Text("20%")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.8, green: 0.7, blue: 0.1))
            }
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.horizontal)

            // Histogram
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<40, id: \.self) { i in
                    let height = CGFloat.random(in: 10...100)
                    let zone = i < 10 ? 1 : i < 20 ? 2 : i < 30 ? 3 : 4
                    Rectangle()
                        .fill(histogramColor(for: zone))
                        .frame(width: 8, height: height)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 120)
            .padding(.horizontal)

            // X-axis labels
            HStack {
                Text("80")
                Spacer()
                Text("100")
                Spacer()
                Text("120")
                Spacer()
                Text("140")
                Spacer()
                Text("160")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Text("Setup.ConnectSensor".localized())
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }

    private var zoneBarPreview: some View {
        HStack(spacing: 0) {
            Text("44%")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(red: 0.3, green: 0.3, blue: 0.8))
            Text("37%")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(.green)
            Text("20%")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(red: 0.8, green: 0.7, blue: 0.1))
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .padding(.horizontal)
        .padding(.top, 12)
    }

    private func zoneStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func zoneColor(for hr: Int) -> Color {
        if hr < 110 { return .blue }
        if hr < 130 { return Color(red: 0.2, green: 0.6, blue: 0.8) }
        if hr < 150 { return .green }
        if hr < 165 { return Color(red: 0.8, green: 0.7, blue: 0.1) }
        return .red
    }

    private func histogramColor(for zone: Int) -> Color {
        switch zone {
        case 1: return .blue
        case 2: return .green
        case 3: return Color(red: 0.8, green: 0.7, blue: 0.1)
        case 4: return .red
        default: return .gray
        }
    }

    // MARK: - Helpers

    private func checkLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
