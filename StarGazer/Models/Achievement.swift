import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var name: String
    var achievementDescription: String
    var iconName: String
    var unlockedDate: Date?
    var progress: Int
    var target: Int

    var isUnlocked: Bool { unlockedDate != nil }

    init(
        id: UUID = UUID(),
        name: String,
        achievementDescription: String,
        iconName: String,
        unlockedDate: Date? = nil,
        progress: Int = 0,
        target: Int = 1
    ) {
        self.id = id
        self.name = name
        self.achievementDescription = achievementDescription
        self.iconName = iconName
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.target = target
    }

    static func seedDefaults() -> [Achievement] {
        [
            Achievement(name: "First glance", achievementDescription: "Your first sky point", iconName: "star.fill", target: 1),
            Achievement(name: "Star drifter", achievementDescription: "10 observations", iconName: "sparkles", target: 10),
            Achievement(name: "ISS Hunter", achievementDescription: "Capture an ISS pass", iconName: "airplane", target: 1),
            Achievement(name: "Moon walker", achievementDescription: "Capture all moon phases", iconName: "moon.stars.fill", target: 8),
            Achievement(name: "Explorer", achievementDescription: "Observe from 5 different locations", iconName: "map.fill", target: 5)
        ]
    }
}
