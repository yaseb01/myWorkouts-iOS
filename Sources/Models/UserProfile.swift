import Foundation
import SwiftData

@Model
final class UserProfile {
    var gender: Gender?
    var birthDate: Date?
    var weight: Double?
    var height: Double?
    var vo2max: Double?
    var unitSystem: UnitSystem

    init(gender: Gender? = nil, birthDate: Date? = nil, weight: Double? = nil,
         height: Double? = nil, vo2max: Double? = nil, unitSystem: UnitSystem = .metric) {
        self.gender = gender
        self.birthDate = birthDate
        self.weight = weight
        self.height = height
        self.vo2max = vo2max
        self.unitSystem = unitSystem
    }
}
