import UIKit

class Show: UIDocument {
    
    static let shared = Show(fileURL: Show.defaultURL)
    
    static var defaultURL: URL = {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { fatalError("Unable to access documents") }
        return directory.appendingPathComponent("show.json")
    }()
    
    override init(fileURL url: URL) {
        super.init(fileURL: url)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            open()
        } else {
            save(to: fileURL, for: .forCreating)
        }
    }
    
    var stings = [Sting]() {
        didSet {
            NotificationCenter.default.post(Notification(name: .stingsDidChange))
            updateChangeCount(.done)
        }
    }
    
    func newShow() {
        stings = [Sting]()
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
