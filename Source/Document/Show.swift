import UIKit

class Show: UIDocument {
    
    static var defaultName = "Show"
    
    override var fileType: String { return "uk.pixlwave.stingpad.show" }
    
    var fileExists: Bool { return FileManager.default.fileExists(atPath: fileURL.path) }
    var fileName: String { return fileURL.deletingPathExtension().lastPathComponent }
    
    private(set) var stings = [Sting]() {
        didSet { NotificationCenter.default.post(Notification(name: .stingsDidChange, object: self)) }
    }
    
    var unavailableFiles: [Sting] { stings.filter { $0.availability != .available && $0.url.isFileURL } }
    var unavailableSongs: [Sting] { stings.filter { $0.availability != .available && $0.url.isMediaItem } }
    
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
        FolderBookmarks.shared.startAccessingSecurityScopedResources()
        defer { FolderBookmarks.shared.stopAccessingSecurityScopedResources() }
        
        let stings = try JSONDecoder().decode([Sting].self, from: data)
        self.stings = stings
    }
    
    override func contents(forType typeName: String) throws -> Any {
        let jsonData = try JSONEncoder().encode(stings)
        return jsonData
    }
    
    func reloadUnavailableStings() {
        FolderBookmarks.shared.startAccessingSecurityScopedResources()
        defer { FolderBookmarks.shared.stopAccessingSecurityScopedResources() }
        
        unavailableSongs.forEach { $0.reloadAudioWithBookmarks() }
        unavailableFiles.forEach { $0.reloadAudioWithBookmarks() }
        
        // updates any changes in sting management list
        NotificationCenter.default.post(name: .didTryReloadingUnavailableStings, object: nil)
    }
    
    // editing functions exist to allow the show to load without updating it's change count
    func append(_ sting: Sting) {
        stings.append(sting)
        undoManager.registerUndo(withTarget: self) { _ in
            self.removeSting(at: self.stings.count - 1)
        }
    }
    
    func insert(_ sting: Sting, at index: Int) {
        stings.insert(sting, at: index)
        undoManager.registerUndo(withTarget: self) { _ in
            self.removeSting(at: index)
        }
    }
    
    func moveSting(from sourceIndex: Int, to destinationIndex: Int) {
        stings.insert(stings.remove(at: sourceIndex), at: destinationIndex)
        undoManager.registerUndo(withTarget: self) { _ in
            self.moveSting(from: destinationIndex, to: sourceIndex)
        }
    }
    
    @discardableResult
    func removeSting(at index: Int) -> Sting {
        let sting = stings.remove(at: index)
        undoManager.registerUndo(withTarget: self) { _ in
            self.insert(sting, at: index)
        }
        
        return sting
    }
    
}
