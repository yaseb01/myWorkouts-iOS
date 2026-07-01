import Foundation
import SwiftData

@Model
final class SensorSample {
    var timestamp: Date
    var type: SensorType
    var value: Double
    var unit: String

    var workout: Workout?

    init(timestamp: Date = Date(), type: SensorType, value: Double, unit: String) {
        self.timestamp = timestamp
        self.type = type
        self.value = value
        self.unit = unit
    }
}
