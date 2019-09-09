import UIKit

class Show: UIDocument {
    
    static var shared = Show(fileURL: Show.defaultURL)
    
    static var defaultURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("Show.stings")
    
    override var fileType: String { return "uk.pixlwave.stingpad.show" }
    
    var fileExists: Bool { return FileManager.default.fileExists(atPath: fileURL.path) }
    
    var stings = [Sting]() {
        didSet {
            NotificationCenter.default.post(Notification(name: .stingsDidChange, object: self))
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
