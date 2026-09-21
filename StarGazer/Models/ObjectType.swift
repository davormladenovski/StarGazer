import SwiftUI

enum ObjectType: String, Codable, CaseIterable, Identifiable {
    case moon = "Moon"
    case planet = "Planet"
    case star = "Star"
    case iss = "ISS"
    case meteor = "Meteor"
    case galaxy = "Galaxy"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .moon: return "moon.stars.fill"
        case .planet: return "circle.dotted"
        case .star: return "star.fill"
        case .iss: return "airplane"
        case .meteor: return "sparkles"
        case .galaxy: return "circle.hexagonpath.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .moon: return ColorTheme.textSecondary
        case .planet: return ColorTheme.primaryAccent
        case .star: return ColorTheme.secondaryAccent
        case .iss: return .cyan
        case .meteor: return .orange
        case .galaxy: return .purple
        case .other: return .gray
        }
    }
}
