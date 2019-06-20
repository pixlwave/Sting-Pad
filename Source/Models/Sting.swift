import Foundation
import AVFoundation
import MediaPlayer

class Sting: NSObject, Codable {
    
    static let defaultURL = URL(fileURLWithPath: Bundle.main.path(forResource: "ComputerMagic", ofType: "m4a")!)
    
    weak var delegate: StingDelegate?
    
    let url: URL
    let songTitle: String
    let songArtist: String
    
    var name: String?
    var color: Color = .default
    private var startTime: TimeInterval = 0 {
        didSet {
            stingPlayer.currentTime = startTime
            stingPlayer.prepareToPlay()
        }
    }
    private var endTime: TimeInterval?
    var numberOfLoops = 0 { didSet { stingPlayer.numberOfLoops = numberOfLoops } }
    
    var normalisedStartTime: Double {
        get { return startTime / stingPlayer.duration }
        set { startTime = newValue * stingPlayer.duration }
    }
    
    private let stingPlayer: AVAudioPlayer
    
    enum CodingKeys: String, CodingKey {
        case url
        case name
        case color
        case startTime
        case endTime
        case numberOfLoops
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let name = try? container.decode(String.self, forKey: .name)
        let color = try container.decode(Color.self, forKey: .color)
        let startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        let endTime = try? container.decode(TimeInterval.self, forKey: .endTime)
        let numberOfLoops = try container.decode(Int.self, forKey: .numberOfLoops)
        
        if let stingPlayer = try? AVAudioPlayer(contentsOf: url) {
            self.url = url
            self.name = name
            self.color = color
            self.startTime = startTime
            self.endTime = endTime
            self.numberOfLoops = numberOfLoops
            self.songTitle = url.songTitle() ?? "Unknown"
            self.songArtist = url.songArtist() ?? "Unknown"
            self.stingPlayer = stingPlayer
        } else {    #warning("Replace this with a \"missing\" Sting object")
            self.url = Sting.defaultURL
            self.songTitle = "Chime"
            self.songArtist = "Default Sting"
            self.stingPlayer = try! AVAudioPlayer(contentsOf: self.url)
        }
        
        super.init()
        configure()
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let stingPlayer = try? AVAudioPlayer(contentsOf: assetURL) else { return nil }
        
        url = assetURL
        songTitle = mediaItem.title ?? "Unknown"
        songArtist = mediaItem.artist ?? "Unknown"
        self.stingPlayer = stingPlayer
        
        super.init()
        configure()
    }
    
    init?(url: URL) {
        guard let stingPlayer = try? AVAudioPlayer(contentsOf: url) else { return nil }
        
        self.url = url
        songTitle = url.songTitle() ?? "Unknown"
        songArtist = url.songArtist() ?? "Unknown"
        self.stingPlayer = stingPlayer
        
        super.init()
        configure()
    }
    
    func configure() {
        updateDelegate()
        updateOutputChannels()
        
        stingPlayer.delegate = self
        seekToStart()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateOutputChannels), name: .outputChannelsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDelegate), name: .stingDelegateDidChange, object: nil)
    }
    
    @objc func updateOutputChannels() {
        stingPlayer.channelAssignments = Engine.shared.outputChannels()
    }
    
    @objc func updateDelegate() {
        delegate = Engine.shared.stingDelegate
    }
    
    func play() {
        stingPlayer.play()
        delegate?.stingDidStartPlaying(self)
    }
    
    func stop() {
        stingPlayer.stop()
        delegate?.stingDidStopPlaying(self)
        seekToStart()
    }
    
    func seekToStart() {
        stingPlayer.currentTime = startTime
        if !stingPlayer.isPlaying { stingPlayer.prepareToPlay() }
    }
    
}


// MARK: AVAudioPlayerDelegate
extension Sting: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.stingDidStopPlaying(self)
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        delegate?.stingDidStopPlaying(self)
    }
}

protocol StingDelegate: AnyObject {
    func stingDidStartPlaying(_ sting: Sting)
    func stingDidStopPlaying(_ sting: Sting)
}
