import UIKit

class ShowDocument: UIDocument {
    
    static var defaultURL: URL = {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { fatalError("Unable to access documents") }
        return directory.appendingPathComponent("show.json")
    }()
    
    var stings = [Sting]() {
        didSet {
            NotificationCenter.default.post(Notification(name: .stingsDidChange))
            updateChangeCount(.done)
        }
    }
    
    enum DocumentError: Error {
        case invalidData
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else { throw DocumentError.invalidData }
        let stings = try JSONDecoder().decode([Sting].self, from: data)
        self.stings = stings
    }
    
    override func contents(forType typeName: String) throws -> Any {
        let jsonData = try JSONEncoder().encode(stings)
        return jsonData
    }
    
}
