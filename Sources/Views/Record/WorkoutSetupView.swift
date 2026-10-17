import SwiftUI
import SwiftData

struct WorkoutSetupView: View {
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(LocationManager.self) private var locationManager
    @Environment(SensorManager.self) private var sensorManager
    @Query(sort: \SportType.name) private var sportTypes: [SportType]

    @State private var selectedSportType: SportType?
    @State private var intensity: IntensityLevel = .moderate
    @State private var useCustomHR = false
    @State private var customMinHR: Int = 120
    @State private var customMaxHR: Int = 160
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
                Button {
                    Haptics.tap()
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
                customMinHR: useCustomHR ? customMinHR : nil,
                customMaxHR: useCustomHR ? customMaxHR : nil,
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

                // Intensity Level
                VStack(spacing: 12) {
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

                    Toggle(isOn: $useCustomHR) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Setup.UseCustomHR".localized())
                                .foregroundStyle(.white)
                            Text("Setup.CustomHRRange".localized())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.green)

                    if useCustomHR {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("HRZones.MinHR".localized())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    TextField("", value: $customMinHR, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                    Text("bpm")
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .leading) {
                                Text("HRZones.MaxHR".localized())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    TextField("", value: $customMaxHR, format: .number)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                    Text("bpm")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
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
            .scrollDismissesKeyboard(.immediately)
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
            Text("Timer.bpm".localized())
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 180)
                .overlay {
                    VStack {
                        Text("\(sensorManager.currentHeartRate)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                            .monospacedDigit()
                        Text("Timer.bpm".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "Setup.ConnectedTo".localized(), sensorManager.deviceName))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
        }
    }

    private var sampleHRChart: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Setup.ConnectSensor".localized())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
        }
    }

    // MARK: - Helpers

    private func checkLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
