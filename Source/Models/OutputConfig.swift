import Foundation

struct OutputConfig: Codable, Hashable {
    static let `default` = OutputConfig(left: 0, right: 1)
    
    let left: Int
    let right: Int
    
    var name: String { "Channels \(left + 1) & \(right + 1)" }
    
    var highestChannel: Int { [left, right].sorted()[1] }
    
    var isDefault: Bool { left == 0 && right == 1 }
    
    static func config(for index: Int) -> OutputConfig {
        OutputConfig(left: 2 * index, right: (2 * index) + 1)
    }
    
    static func array() -> [OutputConfig] {
        var configs = [OutputConfig]()
        for i in 0..<Engine.shared.outputChannelCount() / 2 {
            configs.append(config(for: i))
        }
        return configs
    }
}


