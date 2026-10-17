import Foundation
import SwiftUI

// MARK: - Shared Workout Colors
// Single source of truth for intensity and heart-rate zone colors, so every
// screen displays the same visual language.

enum WorkoutColors {
    static func intensity(_ level: IntensityLevel) -> Color {
        switch level {
        case .easy: return Color(hex: "#9966CC") ?? .purple
        case .moderate: return Color(hex: "#34C759") ?? .green
        case .hard: return Color(hex: "#FF9500") ?? .orange
        case .veryHard: return Color(hex: "#FF3B30") ?? .red
        case .maximum: return Color(hex: "#E63333") ?? .red
        }
    }

    static func heartRate(_ hr: Int, zoneMin: Int, zoneMax: Int) -> Color {
        if hr < zoneMin { return .blue }
        if hr <= zoneMax { return .green }
        if hr <= zoneMax + 20 { return Color(.systemYellow) }
        return .red
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

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

    var abbreviation: String {
        switch self {
        case .easy: return "G1"
        case .moderate: return "G2"
        case .hard: return "G3"
        case .veryHard: return "G4"
        case .maximum: return "G5"
        }
    }

    var minHR: Int {
        switch self {
        case .easy: return 95
        case .moderate: return 114
        case .hard: return 133
        case .veryHard: return 152
        case .maximum: return 171
        }
    }

    var maxHR: Int {
        switch self {
        case .easy: return 114
        case .moderate: return 133
        case .hard: return 152
        case .veryHard: return 171
        case .maximum: return 190
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
