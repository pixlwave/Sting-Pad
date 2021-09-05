import Foundation
import AVFoundation
import MediaPlayer
import os.log

class Sting: NSObject, Codable, ObservableObject {
    
    private(set) var url: URL
    private(set) var bookmark: Data?
    
    var name: String?
    var color: Color = .default
    
    private(set) var metadata: Metadata
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
        get {
            guard let audioFile = audioFile else { return 0 }
            return AVAudioFramePosition(startTime * audioFile.fileFormat.sampleRate)
        }
        set {
            guard let audioFile = audioFile else { return }
            startTime = Double(newValue) / Double(audioFile.fileFormat.sampleRate)
        }
    }
    var endSample: AVAudioFramePosition {
        get {
            guard let audioFile = audioFile else { return 0 }
            if let endTime = endTime {
                return AVAudioFramePosition(endTime * audioFile.fileFormat.sampleRate)
            } else {
                return audioFile.length
            }
        }
        set {
            guard let audioFile = audioFile else { return }
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
        guard let audioFile = audioFile else { return 0 }
        return Double(sampleCount) / audioFile.processingFormat.sampleRate
    }
    
    private(set) var audioFile: AVAudioFile?
    private(set) var buffer: AVAudioPCMBuffer?
    @Published private(set) var availability: Availability
    
    enum Availability: String {
        case available
        case noPermission = "Permission denied"
        case noSuchFile = "File is missing"
        case noSuchSong = "Song is missing"
        case isCloudSong = "Song is in the Cloud"
        case unknown = "Unknown"
    }
    
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
        var bookmark = try? container.decode(Data.self, forKey: .bookmark)
        let name = try? container.decode(String.self, forKey: .name)
        let color = try container.decode(Color.self, forKey: .color)
        let metadata = try container.decode(Metadata.self, forKey: .metadata)
        var startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        var endTime = try? container.decode(TimeInterval.self, forKey: .endTime)
        let loops = try container.decode(Bool.self, forKey: .loops)
        
        var isStale = false
        if let data = bookmark, let resolvedURL = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) {
            url = resolvedURL
            
            if isStale, let freshBookmark = try? url.bookmarkData() {
                bookmark = freshBookmark
            }
        }
        
        let hasSecurityScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        if let audioFile = try? AVAudioFile(forReading: url) {
            self.audioFile = audioFile
            availability = .available
        } else if url.isMediaItem {
            if let matchingAsset = metadata.matchingAsset {
                if let assetURL = matchingAsset.assetURL, let audioFile = try? AVAudioFile(forReading: assetURL) {
                    url = assetURL
                    self.audioFile = audioFile
                    availability = .available
                } else if matchingAsset.isCloudItem {
                    self.audioFile = nil
                    availability = .isCloudSong
                } else {
                    self.audioFile = nil
                    availability = .unknown
                    os_log("Song access error: Song has a local asset, unsure why load failed.")
                }
            } else {
                self.audioFile = nil
                availability = .noSuchSong
            }
        } else {    // is a file
            self.audioFile = nil
            do {
                _ = try url.checkResourceIsReachable()
                availability = .unknown
                os_log("File URL access error: Resource is reachable, unsure why load failed.")
            } catch let error as NSError {
                switch error.code {
                case NSFileReadNoSuchFileError:
                    availability = .noSuchFile
                case NSFileReadNoPermissionError:
                    availability = .noPermission
                default:
                    availability = .unknown
                    os_log("File URL access error: %@", String(describing: error))
                }
            }
        }
        
        self.url = url
        self.bookmark = bookmark
        self.name = name
        self.color = color
        self.metadata = metadata
        
        super.init()
        
        validateNew(startTime: &startTime, endTime: &endTime)
        
        self.startTime = startTime
        self.endTime = endTime
        self.loops = loops
        
        if loops { createBuffer() }
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let audioFile = try? AVAudioFile(forReading: assetURL) else { return nil }
        
        url = assetURL
        bookmark = nil
        metadata = Metadata(mediaItem: mediaItem)
        self.audioFile = audioFile
        availability = .available
        
        super.init()
        
        loadPreset()
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
        metadata = Metadata(url: url)
        self.audioFile = audioFile
        availability = .available
        
        super.init()
        
        loadPreset()
    }
    
    func reloadAudio(from sting: Sting) {
        url = sting.url
        bookmark = sting.bookmark
        metadata = sting.metadata
        audioFile = sting.audioFile
        availability = sting.availability
        
        // ensure start and end times are valid for new audio file
        validateStartTimeAndEndTime()
        
        if loops { createBuffer() }
    }
    
    func reloadAudioWithBookmarks() {
        // reload the audio file
        guard let audioFile = try? AVAudioFile(forReading: url) else {
            // update availability: file may switch from no permission to no such file
            if url.isFileURL {
                do {
                    _ = try url.checkResourceIsReachable()
                    availability = .unknown
                    os_log("File URL access error: Resource is reachable, unsure why load failed.")
                } catch let error as NSError {
                    switch error.code {
                    case NSFileReadNoSuchFileError:
                        availability = .noSuchFile
                    case NSFileReadNoPermissionError:
                        availability = .noPermission
                    default:
                        availability = .unknown
                        os_log("File URL access error: %@", String(describing: error))
                    }
                }
            }
            return
        }
        
        // update any bookmark data for the url
        if let newBookmark = try? url.bookmarkData() {
            bookmark = newBookmark
        }
        
        self.audioFile = audioFile
        availability = .available
        
        // ensure start and end times are valid for new audio file
        validateStartTimeAndEndTime()
        
        if loops { createBuffer() }
        
        NotificationCenter.default.post(name: .didFinishEditing, object: self)
    }
    
    func createBuffer() {
        guard let audioFile = audioFile else { return }
        
        buffer = AVAudioPCMBuffer(for: audioFile)
        updateBuffer()
    }
    
    func updateBuffer() {
        guard let audioFile = audioFile, loops, let buffer = buffer else { return }
        
        do {
            audioFile.framePosition = startSample
            try audioFile.read(into: buffer, frameCount: AVAudioFrameCount(endSample - startSample))
        } catch {
            os_log("Error updating loop buffer: %@", String(describing: error))
        }
    }
    
    func destroyBuffer() {
        buffer = nil
    }
    
    func setPreset() {
        if startTime == 0 && endTime == nil && loops == false {
            UserDefaults.presets.removeObject(forKey: url.absoluteString)
        } else {
            let preset = Preset(startTime: startTime, endTime: endTime, loops: loops)
            guard let data = try? JSONEncoder().encode(preset) else { return }
            UserDefaults.presets.setValue(data, forKey: url.absoluteString)
        }
    }
    
    func loadPreset() {
        guard
            let data = UserDefaults.presets.data(forKey: url.absoluteString),
            let preset = try? JSONDecoder().decode(Preset.self, from: data)
        else { return }
        
        var startTime = preset.startTime
        var endTime = preset.endTime
        
        validateNew(startTime: &startTime, endTime: &endTime)
        
        self.startTime = startTime
        self.endTime = endTime
        self.loops = preset.loops
    }
    
    /// Validate ``startTime`` and ``endTime`` properties, updating them when necessary
    func validateStartTimeAndEndTime() {
        // make copies of the current start and end times otherwise
        // validation can crash by accessing the mutated inout value
        var startTime = startTime
        var endTime = endTime
        
        // reset the current values to ensure it is safe to set them
        // one before the other (as the buffer is updated each time)
        self.startTime = 0
        self.endTime = nil
        
        // ensure start and end times are valid for the audio file
        validateNew(startTime: &startTime, endTime: &endTime)
        
        // set the times after validation has taken place
        self.startTime = startTime
        self.endTime = endTime
    }
    
    /// Ensures the values passed in are valid start and end times for the current audio file.
    /// Do NOT call this method passing in the current ``startTime`` and ``endTime`` properties.
    func validateNew(startTime: inout TimeInterval, endTime: inout TimeInterval?) {
        guard let audioFile = audioFile else { return }    // don't wipe out the times when the audio file is missing
        
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        
        if startTime >= duration {
            startTime = 0
        }
        
        guard let newEndTime = endTime else { return }
        if newEndTime >= duration || newEndTime <= startTime {
            endTime = nil
        }
    }
    
    func copy() -> Sting? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(Sting.self, from: data)
    }
    
    struct Preset: Codable {
        var startTime: TimeInterval
        var endTime: TimeInterval?
        var loops: Bool
    }
    
}


// MARK: Array<Sting>
extension Array where Element: Sting {
    var playable: Self { return self.filter { $0.audioFile != nil } }
}
