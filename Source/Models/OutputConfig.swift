import Foundation

struct OutputConfig: Codable {
    var left: Int
    var right: Int
    
    var highestChannel: Int {
        return [left, right].sorted()[1]
    }
}
