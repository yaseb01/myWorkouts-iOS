import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct GPXImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SportType.name) private var sportTypes: [SportType]

    @State private var selectedSportType: SportType?
    @State private var importedGPXData: GPXData?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingFilePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let gpxData = importedGPXData {
                    gpxPreview(gpxData)
                } else {
                    emptyState
                }
            }
            .padding()
            .navigationTitle("GPX.Import".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized()) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if importedGPXData != nil && selectedSportType != nil {
                        Button("Save".localized()) {
                            saveImportedWorkout()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .xml],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Error".localized(), isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("GPX.SelectFile".localized())
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("GPX.SelectFileDesc".localized())
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button {
                showingFilePicker = true
            } label: {
                Label("GPX.Browse".localized(), systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gpxPreview(_ gpxData: GPXData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sport Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual.SportType".localized())
                        .font(.headline)

                    Picker("Manual.SportType".localized(), selection: $selectedSportType) {
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

                // GPX Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("GPX.TrackInfo".localized())
                        .font(.headline)

                    if let firstPoint = gpxData.trackPoints.first,
                       let lastPoint = gpxData.trackPoints.last {
                        let totalDistance = calculateTotalDistance(gpxData.trackPoints)
                        let elevationGain = calculateElevationGain(gpxData.trackPoints)

                        statRow(label: "GPX.Points".localized(), value: "\(gpxData.trackPoints.count)")
                        statRow(label: "GPX.Distance".localized(), value: String(format: "%.2f km", totalDistance / 1000))
                        statRow(label: "GPX.ElevationGain".localized(), value: String(format: "%.0f m", elevationGain))

                        if let firstTime = firstPoint.timestamp, let lastTime = lastPoint.timestamp {
                            let duration = lastTime.timeIntervalSince(firstTime)
                            statRow(label: "GPX.Duration".localized(), value: formatDuration(duration))
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Map Preview
                if gpxData.trackPoints.count >= 2 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GPX.Preview".localized())
                            .font(.headline)

                        StaticMapTrackView(
                            trackPoints: gpxData.trackPoints.map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            }
                        )
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer()
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "GPX.AccessError".localized()
                showError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                if let gpxData = GPXManager.importGPX(from: data) {
                    importedGPXData = gpxData
                    if selectedSportType == nil {
                        selectedSportType = sportTypes.first
                    }
                } else {
                    errorMessage = "GPX.ParseError".localized()
                    showError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func saveImportedWorkout() {
        guard let gpxData = importedGPXData,
              let sportType = selectedSportType else { return }

        guard let firstPoint = gpxData.trackPoints.first,
              let lastPoint = gpxData.trackPoints.last else { return }

        let firstTime = firstPoint.timestamp ?? Date()
        let lastTime = lastPoint.timestamp ?? Date()
        let duration = lastTime.timeIntervalSince(firstTime)

        let workout = Workout(
            sportType: sportType,
            startTime: firstTime,
            endTime: lastTime,
            duration: duration,
            distance: calculateTotalDistance(gpxData.trackPoints),
            elevationGain: calculateElevationGain(gpxData.trackPoints),
            isManual: true
        )

        for gpxPoint in gpxData.trackPoints {
            let trackPoint = TrackPoint(
                timestamp: gpxPoint.timestamp ?? Date(),
                latitude: gpxPoint.latitude,
                longitude: gpxPoint.longitude,
                altitude: gpxPoint.altitude
            )
            trackPoint.workout = workout
            workout.trackPoints.append(trackPoint)
        }

        modelContext.insert(workout)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "GPX.SaveError".localized()
            showError = true
        }
    }

    private func calculateTotalDistance(_ points: [GPXData.GPXTrackPoint]) -> Double {
        var total: Double = 0
        for i in 1..<points.count {
            let p1 = points[i - 1]
            let p2 = points[i]
            total += distanceBetween(
                lat1: p1.latitude, lon1: p1.longitude,
                lat2: p2.latitude, lon2: p2.longitude
            )
        }
        return total
    }

    private func calculateElevationGain(_ points: [GPXData.GPXTrackPoint]) -> Double {
        var gain: Double = 0
        for i in 1..<points.count {
            if let alt1 = points[i - 1].altitude,
               let alt2 = points[i].altitude {
                let delta = alt2 - alt1
                if delta > 0 {
                    gain += delta
                }
            }
        }
        return gain
    }

    private func distanceBetween(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

import CoreLocation
