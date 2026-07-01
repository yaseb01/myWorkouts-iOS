import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var sportType: SportType?
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var distance: Double
    var calories: Double
    var elevationGain: Double
    var note: String?
    var intensity: IntensityLevel
    var isManual: Bool

    @Relationship(deleteRule: .cascade, inverse: \TrackPoint.workout)
    var trackPoints: [TrackPoint]

    @Relationship(deleteRule: .cascade, inverse: \SensorSample.workout)
    var sensorSamples: [SensorSample]

    init(id: UUID = UUID(), sportType: SportType? = nil, startTime: Date = Date(),
         endTime: Date? = nil, duration: TimeInterval = 0, distance: Double = 0,
         calories: Double = 0, elevationGain: Double = 0, note: String? = nil,
         intensity: IntensityLevel = .moderate, isManual: Bool = false) {
        self.id = id
        self.sportType = sportType
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.distance = distance
        self.calories = calories
        self.elevationGain = elevationGain
        self.note = note
        self.intensity = intensity
        self.isManual = isManual
        self.trackPoints = []
        self.sensorSamples = []
    }
}
