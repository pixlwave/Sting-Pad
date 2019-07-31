import Foundation

@propertyWrapper
struct UserDefault<T> {
    var key: String
    var defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get { return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

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
