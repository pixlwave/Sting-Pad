import UIKit

class Show: UIDocument {
    
    static var defaultName = "Show"
    
    override var fileType: String { return "uk.pixlwave.stingpad.show" }
    
    var fileExists: Bool { return FileManager.default.fileExists(atPath: fileURL.path) }
    var fileName: String { return fileURL.deletingPathExtension().lastPathComponent }
    
    private(set) var stings = [Sting]() {
        didSet { NotificationCenter.default.post(Notification(name: .stingsDidChange, object: self)) }
    }
    
    enum DocumentError: Error {
        case invalidData
    }
    
    convenience init(name: String?) {
        let fileName: String
        
        if let name = name, !name.isEmpty {
            fileName = name
        } else {
            fileName = Show.defaultName
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).stings")
        
        self.init(fileURL: url)
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
    
    // editing functions exist to allow the show to load without updating it's change count
    func append(_ sting: Sting) {
        stings.append(sting)
        updateChangeCount(.done)
    }
    
    func insert(_ sting: Sting, at index: Int) {
        stings.insert(sting, at: index)
        updateChangeCount(.done)
    }
    
    @discardableResult
    func removeSting(at index: Int) -> Sting {
        let sting = stings.remove(at: index)
        updateChangeCount(.done)
        
        return sting
    }
    
}
