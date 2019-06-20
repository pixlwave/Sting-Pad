import UIKit

enum Color: String, Codable {
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
            return .black
        case .gray:
            return .gray
        case .light:
            return .white
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .teal:
            return UIColor(red: 0.463, green: 0.776, blue: 0.961, alpha: 1.0)
        case .blue:
            return .blue
        case .indigo:
            return UIColor(red: 0.337, green: 0.353, blue: 0.812, alpha: 1.0)
        case .purple:
            return .purple
        case .pink:
            return UIColor(red: 0.922, green: 0.271, blue: 0.353, alpha: 1.0)
        }
    }
}
