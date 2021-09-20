import UIKit
import SwiftUI

extension Sting {
    enum Color: String, Codable, CaseIterable {
        case dark
        case gray
        case light
        case red
        case orange
        case yellow
        case green
        case mint
        case teal
        case cyan
        case blue
        case indigo
        case purple
        case pink
        
        static var `default`: Color = Color(rawValue: UserDefaults.standard.string(forKey: "defaultColor") ?? "dark" ) ?? .dark {
            didSet { UserDefaults.standard.set(`default`.rawValue, forKey: "defaultColor")}
        }
        
        var object: UIColor {
            switch self {
            case .dark:
                return .darkGray
            case .gray:
                return .gray
            case .light:
                return .lightGray
            case .red:
                return .systemRed
            case .orange:
                return .systemOrange
            case .yellow:
                return .systemYellow
            case .green:
                return .systemGreen
            case .mint:
                return .systemMint
            case .teal:
                return .systemTeal
            case .cyan:
                return .systemCyan
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
        
        var value: SwiftUI.Color {
            SwiftUI.Color(object)
        }
    }
}
