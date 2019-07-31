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
    @Stored(key: "defaultColor", defaultValue: .dark) var defaultColor: Color
    
    private init() {}
    
    @propertyWrapper
    struct Stored<T> {
        var key: String
        var value: T { didSet { UserDefaults.standard.set(value, forKey: key) } }
        
        init(key: String, defaultValue: T) {
            self.key = key
            self.value = UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        
        var wrappedValue: T {
            get { return value }
            set { value = newValue }
        }
    }

}
