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
                Button("CANCEL") {
                    // dismiss or pop
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
                        Text("START")
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
        .navigationTitle("Start Workout")
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
                    Text("Workout Type")
                        .foregroundStyle(.white)
                    Spacer()
                    Picker("", selection: $selectedSportType) {
                        Text("None").tag(nil as SportType?)
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
                    Text("Level")
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
                    Text("Note")
                        .foregroundStyle(.secondary)
                    TextField("Optional note", text: $note, axis: .vertical)
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
                Label("Track route", systemImage: "map")
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
                    Text("GPS recording enabled")
                        .foregroundStyle(.white)
                    Spacer()
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Enable") {
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
                Label("Bluetooth LE HR Sensor", systemImage: "heart.fill")
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
                                Text("Battery: \(sensorManager.batteryLevel)%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Disconnect") {
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
                            Text(sensorManager.isScanning ? "Scanning..." : "Scan for Sensors")
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

    // MARK: - Sensor Tab

    private var sensorTab: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Additional sensor configuration will be available in future updates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func checkLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
