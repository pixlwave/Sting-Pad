import UIKit

enum Color: String, Codable, CaseIterable {
    case dark
    case gray
    case light
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case indigo
    case purple
    case pink
    
    static let `default` = Color.dark
    
    var value: UIColor {
        switch self {
        case .dark:
            return .systemGray
        case .gray:
            return .systemGray3
        case .light:
            return .systemGray6
        case .red:
            return .systemRed
        case .orange:
            return .systemOrange
        case .yellow:
            return .systemYellow
        case .green:
            return .systemGreen
        case .teal:
            return .systemTeal
        case .blue:
            return .systemBlue
        case .indigo:
            return .systemIndigo
        case .purple:
            return .systemPurple
        case .pink:
            return .systemPink
        }
    }
}
