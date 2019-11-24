import Foundation
import AVFoundation
import MediaPlayer

class Sting: NSObject, Codable {
    
    let url: URL
    let bookmark: Data?
    let isMissing: Bool
    
    var name: String?
    var color: Color = .default
    
    let metadata: Metadata
    var songTitle: String { metadata.title ?? "Unknown Title" }
    var songArtist: String { metadata.artist ?? "Unknown Artist" }
    
    private var startTime: TimeInterval = 0 { didSet { updateBuffer() } }
    private var endTime: TimeInterval? { didSet { updateBuffer() } }
    var loops = false {
        didSet {
            if loops { createBuffer() }
            else { destroyBuffer() }
        }
    }
    
    var startSample: AVAudioFramePosition {
        get { return AVAudioFramePosition(startTime * audioFile.fileFormat.sampleRate) }
        set { startTime = Double(newValue) / Double(audioFile.fileFormat.sampleRate) }
    }
    var endSample: AVAudioFramePosition {
        get {
            if let endTime = endTime {
                return AVAudioFramePosition(endTime * audioFile.fileFormat.sampleRate)
            } else {
                return audioFile.length
            }
        }
        set {
            if newValue < audioFile.length {
                endTime = Double(newValue) / Double(audioFile.fileFormat.sampleRate)
            } else {
                endTime = nil
            }
        }
    }
    var sampleCount: AVAudioFrameCount {
        AVAudioFrameCount(endSample - startSample)
    }
    var totalTime: TimeInterval {
        Double(sampleCount) / audioFile.processingFormat.sampleRate
    }
    
    let audioFile: AVAudioFile
    private(set) var buffer: AVAudioPCMBuffer?
    
    enum CodingKeys: String, CodingKey {
        case url
        case bookmark
        case name
        case color
        case metadata
        case startTime
        case endTime
        case loops
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var url = try container.decode(URL.self, forKey: .url)
        let bookmark = try? container.decode(Data.self, forKey: .bookmark)
        let name = try? container.decode(String.self, forKey: .name)
        let color = try container.decode(Color.self, forKey: .color)
        let metadata = try container.decode(Metadata.self, forKey: .metadata)
        let startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        let endTime = try? container.decode(TimeInterval.self, forKey: .endTime)
        let loops = try container.decode(Bool.self, forKey: .loops)
        
        var isStale = false
        if let bookmark = bookmark, let resolvedURL = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale) {
            url = resolvedURL
        }
        
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if let audioFile = try? AVAudioFile(forReading: url) {
            self.isMissing = false
            self.audioFile = audioFile
        } else if url.isMediaItem, let assetURL = metadata.matchingAssetURL, let audioFile = try? AVAudioFile(forReading: assetURL) {
            url = assetURL
            self.isMissing = false
            self.audioFile = audioFile
        } else {
            self.isMissing = true
            self.audioFile = AVAudioFile()
        }
        
        self.url = url
        self.bookmark = bookmark
        self.name = name
        self.color = color
        self.metadata = metadata
        self.startTime = startTime
        self.endTime = endTime
        self.loops = loops
        
        super.init()
        
        if loops { createBuffer() }
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let audioFile = try? AVAudioFile(forReading: assetURL) else { return nil }
        
        url = assetURL
        bookmark = nil
        isMissing = false
        metadata = Metadata(mediaItem: mediaItem)
        self.audioFile = audioFile
        
        super.init()
        
        loadDefaults()
    }
    
    init?(url: URL) {
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let audioFile = try? AVAudioFile(forReading: url) else { return nil }
        
        self.url = url
        bookmark = try? url.bookmarkData()
        isMissing = false
        metadata = Metadata(url: url)
        self.audioFile = audioFile
        
        super.init()
        
        loadDefaults()
    }
    
    func createBuffer() {
        guard !isMissing else { return }
        
        buffer = AVAudioPCMBuffer(for: audioFile)
        updateBuffer()
    }
    
    func updateBuffer() {
        guard loops, let buffer = buffer else { return }
        
        do {
            audioFile.framePosition = startSample
            try audioFile.read(into: buffer, frameCount: AVAudioFrameCount(endSample - startSample))
        } catch {
            print("Error: \(error)")
        }
    }
    
    func destroyBuffer() {
        buffer = nil
    }
    
    func storeDefaults() {
        if startTime == 0 && endTime == nil && loops == false {
            UserDefaults.stings.removeObject(forKey: url.absoluteString)
        } else {
            let defaults = Defaults(startTime: startTime, endTime: endTime, loops: loops)
            guard let data = try? JSONEncoder().encode(defaults) else { return }
            UserDefaults.stings.setValue(data, forKey: url.absoluteString)
        }
    }
    
    func loadDefaults() {
        guard
            let data = UserDefaults.stings.data(forKey: url.absoluteString),
            let defaults = try? JSONDecoder().decode(Defaults.self, from: data)
        else { return }
        
        #warning("Add range checks")
        startTime = defaults.startTime
        endTime = defaults.endTime
        loops = defaults.loops
    }
    
    func copy() -> Sting? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(Sting.self, from: data)
    }
    
    struct Defaults: Codable {
        var startTime: TimeInterval
        var endTime: TimeInterval?
        var loops: Bool
    }
    
}


// MARK: Array<Sting>
extension Array where Element: Sting {
    var playable: Self { return self.filter { !$0.isMissing } }
}
