import Foundation
import SwiftData

@Model
final class SportType {
    var id: UUID
    var name: String
    var abbreviation: String
    var color: String
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, abbreviation: String, color: String = "#007AFF", isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.color = color
        self.isFavorite = isFavorite
    }
}
