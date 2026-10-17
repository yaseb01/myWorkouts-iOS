import Foundation
import SwiftUI
import UIKit

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

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        guard length == 6 || length == 8 else { return nil }

        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1.0
        } else {
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Geo Math

enum GeoMath {
    /// Great-circle distance between two coordinates in meters (haversine).
    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

// MARK: - Duration Formatting

enum DurationFormat {
    /// Digital clock format: "1:05:09" (with hours) or "05:09".
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    /// Compact human format: "2h 15m" or "15m".
    static func hoursMinutes(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        return "\(m)m"
    }

    /// Short statistical format used by the home statistics table:
    /// "1:05" with hours, otherwise minutes with a tick ("65'").
    static func short(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return String(format: "%d:%02d", h, m)
        }
        return String(format: "%d'", m)
    }
}
