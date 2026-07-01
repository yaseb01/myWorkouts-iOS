import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var type: GoalType
    var weeklyTarget: Double
    var unit: String
    var weight: Int
    var isActive: Bool

    init(id: UUID = UUID(), type: GoalType, weeklyTarget: Double, weight: Int = 1, isActive: Bool = true) {
        self.id = id
        self.type = type
        self.weeklyTarget = weeklyTarget
        self.unit = type.unit
        self.weight = weight
        self.isActive = isActive
    }
}
