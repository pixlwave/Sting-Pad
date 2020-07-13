import Foundation

struct ChannelPair: Codable, Hashable {
    static let `default` = ChannelPair(left: 0, right: 1)
    
    let left: Int
    let right: Int
    
    var name: String { "Channels \(left + 1) & \(right + 1)" }
    
    var highestChannel: Int { [left, right].sorted()[1] }
    
    var isDefault: Bool { left == 0 && right == 1 }
    
    static func config(for index: Int) -> ChannelPair {
        ChannelPair(left: 2 * index, right: (2 * index) + 1)
    }
    
    static func array() -> [ChannelPair] {
        if Engine.shared.outputChannelCount() == 1 {
            return [config(for: 0)]
        }
        
        var configs = [ChannelPair]()
        for i in 0..<Engine.shared.outputChannelCount() / 2 {
            configs.append(config(for: i))
        }
        return configs
    }
}


