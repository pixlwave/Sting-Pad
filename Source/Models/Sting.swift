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
    var color: Color
    private var startTime: TimeInterval {
        didSet {
            stingPlayer.currentTime = startTime
            stingPlayer.prepareToPlay()
        }
    }
    private var stopTime: TimeInterval?
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
        case startTime = "cuePoint";    #warning("Remove value after implementing file picker")
        case stopTime
        case numberOfLoops
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let name = try? container.decode(String.self, forKey: .name)
        let color = (try? container.decode(Color.self, forKey: .color)) ?? .default;    #warning("Replace ?? after implementing file picker")
        let startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        let stopTime = try? container.decode(TimeInterval.self, forKey: .stopTime)
        let numberOfLoops = (try? container.decode(Int.self, forKey: .numberOfLoops)) ?? 0; #warning("Replace ?? after implementing file picker")
        
        if let stingPlayer = try? AVAudioPlayer(contentsOf: url) {
            self.url = url
            self.name = name
            self.color = color
            self.startTime = startTime
            self.stopTime = stopTime
            self.numberOfLoops = numberOfLoops
            self.songTitle = url.songTitle() ?? "Unknown"
            self.songArtist = url.songArtist() ?? "Unknown"
            self.stingPlayer = stingPlayer
        } else {    #warning("Replace this with a \"missing\" Sting object")
            self.url = Sting.defaultURL
            self.color = .default
            self.startTime = 0
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
        color = .default
        startTime = 0
        songTitle = mediaItem.title ?? "Unknown"
        songArtist = mediaItem.artist ?? "Unknown"
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
