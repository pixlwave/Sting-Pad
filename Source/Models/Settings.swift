import Foundation

class Settings {
    
    static let shared = Settings()
    
    enum LaunchMode: Int, Codable {
        case toggle, trigger
    }
    
    @Stored(key: "autoCue", defaultValue: false) var autoCue: Bool
    var launchMode: LaunchMode = Settings.LaunchMode(rawValue: UserDefaults.standard.integer(forKey: "launchMode")) ?? .trigger {
        didSet { UserDefaults.standard.set(launchMode.rawValue, forKey: "launchMode") }
    }
    @Stored(key: "showsTransportBar", defaultValue: true) var showsTransportBar: Bool
    
    private init() {}
    
}
