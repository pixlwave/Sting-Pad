import Foundation

struct OutputConfig: Codable {
    static let `default` = OutputConfig(left: 0, right: 1)
    
    var left: Int
    var right: Int
    
    var highestChannel: Int {
        [left, right].sorted()[1]
    }
}
