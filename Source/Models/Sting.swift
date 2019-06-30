import Foundation
import AVFoundation
import MediaPlayer

class Sting: NSObject, Codable {
    
    static let defaultURL = URL(fileURLWithPath: Bundle.main.path(forResource: "ComputerMagic", ofType: "m4a")!)
    
    let url: URL
    let songTitle: String
    let songArtist: String
    
    var name: String?
    var color: Color = .default
    private var startTime: TimeInterval = 0 { didSet { updateBuffer() } }
    private var endTime: TimeInterval?
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
        return AVAudioFrameCount(endSample - startSample)
    }
    
    let audioFile: AVAudioFile
    private(set) var buffer: AVAudioPCMBuffer?
    
    enum CodingKeys: String, CodingKey {
        case url
        case name
        case color
        case startTime
        case endTime
        case loops
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let name = try? container.decode(String.self, forKey: .name)
        let color = try container.decode(Color.self, forKey: .color)
        let startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        let endTime = try? container.decode(TimeInterval.self, forKey: .endTime)
        let loops = try container.decode(Bool.self, forKey: .loops)
        
        if let audioFile = try? AVAudioFile(forReading: url) {
            self.url = url
            self.name = name
            self.color = color
            self.startTime = startTime
            self.endTime = endTime
            self.loops = loops
            self.songTitle = url.songTitle() ?? "Unknown"
            self.songArtist = url.songArtist() ?? "Unknown"
            self.audioFile = audioFile
        } else {    #warning("Replace this with a \"missing\" Sting object")
            self.url = Sting.defaultURL
            self.songTitle = "Chime"
            self.songArtist = "Default Sting"
            self.audioFile = try! AVAudioFile(forReading: self.url)
        }
        
        super.init()
        
        if loops { createBuffer() }
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let audioFile = try? AVAudioFile(forReading: assetURL), let buffer = AVAudioPCMBuffer(for: audioFile) else { return nil }
        
        url = assetURL
        songTitle = mediaItem.title ?? "Unknown"
        songArtist = mediaItem.artist ?? "Unknown"
        self.audioFile = audioFile
        self.buffer = buffer
        
        super.init()
    }
    
    init?(url: URL) {
        guard let audioFile = try? AVAudioFile(forReading: url), let buffer = AVAudioPCMBuffer(for: audioFile) else { return nil }
        
        self.url = url
        songTitle = url.songTitle() ?? "Unknown"
        songArtist = url.songArtist() ?? "Unknown"
        self.audioFile = audioFile
        self.buffer = buffer
        
        super.init()
    }
    
    func createBuffer() {
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
    
}
