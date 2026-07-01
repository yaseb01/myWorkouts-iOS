import Foundation
import SwiftData

@Model
final class HeartRateZone {
    var id: UUID
    var name: String
    var abbreviation: String
    var minHR: Int
    var maxHR: Int
    var zoneNumber: Int

    init(id: UUID = UUID(), name: String, abbreviation: String = "", minHR: Int, maxHR: Int, zoneNumber: Int) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation.isEmpty ? "Z\(zoneNumber)" : abbreviation
        self.minHR = minHR
        self.maxHR = maxHR
        self.zoneNumber = zoneNumber
    }
}
