import Foundation

enum IntensityLevel: Int, Codable, CaseIterable {
    case easy = 1
    case moderate = 2
    case hard = 3
    case veryHard = 4
    case maximum = 5

    var name: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        case .maximum: return "Maximum"
        }
    }
}

enum SensorType: String, Codable, CaseIterable {
    case heartRate
    case cadence
    case speed
    case temperature
}

enum GoalType: String, Codable, CaseIterable {
    case workouts
    case duration
    case calories
    case distance
    case elevation

    var unit: String {
        switch self {
        case .workouts: return "workouts"
        case .duration: return "min"
        case .calories: return "kcal"
        case .distance: return "km"
        case .elevation: return "m"
        }
    }
}

enum Gender: String, Codable, CaseIterable {
    case male
    case female
    case other
    case preferNotToSay
}

enum UnitSystem: String, Codable {
    case metric
    case imperial
}
