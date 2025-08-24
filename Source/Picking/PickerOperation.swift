import Foundation

enum PickerOperation: Identifiable {
    case normal
    case locate(Sting)
    case insert(Int)
    
    var id: String {
        switch self {
        case .normal: "normal"
        case .locate(let sting): "locate:\(sting)"
        case .insert(let int): "insert:\(int)"
        }
    }
}
