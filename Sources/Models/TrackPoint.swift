import Foundation
import SwiftData

@Model
final class TrackPoint {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var horizontalAccuracy: Double?
    var speed: Double?
    var course: Double?

    var workout: Workout?

    init(timestamp: Date = Date(), latitude: Double, longitude: Double, altitude: Double? = nil,
         horizontalAccuracy: Double? = nil, speed: Double? = nil, course: Double? = nil) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.course = course
    }
}
