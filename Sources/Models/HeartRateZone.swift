import Foundation
import SwiftData

@Model
final class HeartRateZone {
    var id: UUID
    var name: String
    var abbreviation: String
    var zoneDescription: String
    var minHR: Int
    var maxHR: Int
    var zoneNumber: Int
    var minPercentage: Double
    var maxPercentage: Double

    init(id: UUID = UUID(), name: String, abbreviation: String = "", zoneDescription: String = "",
         minHR: Int, maxHR: Int, zoneNumber: Int,
         minPercentage: Double = 0, maxPercentage: Double = 100) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation.isEmpty ? "Z\(zoneNumber)" : abbreviation
        self.zoneDescription = zoneDescription
        self.minHR = minHR
        self.maxHR = maxHR
        self.zoneNumber = zoneNumber
        self.minPercentage = minPercentage
        self.maxPercentage = maxPercentage
    }
}
