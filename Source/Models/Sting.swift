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
    private var cuePoint: Double {
        didSet {
            stingPlayer.currentTime = cuePoint
            stingPlayer.prepareToPlay()
        }
    }
    
    var normalisedCuePoint: Double {
        get { return cuePoint / stingPlayer.duration }
        set { cuePoint = newValue * stingPlayer.duration }
    }
    
    private let stingPlayer: AVAudioPlayer
    
    enum CodingKeys: String, CodingKey {
        case url
        case cuePoint
    }
    
    init(url: URL, cuePoint: Double) {
        if let stingPlayer = try? AVAudioPlayer(contentsOf: url) {
            self.url = url
            self.songTitle = url.songTitle() ?? "Unknown"
            self.songArtist = url.songArtist() ?? "Unknown"
            self.cuePoint = cuePoint
            self.stingPlayer = stingPlayer
        } else {    #warning("Test this as a fallthrough case")
            self.url = Sting.defaultURL
            self.stingPlayer = try! AVAudioPlayer(contentsOf: self.url)
            self.songTitle = "Chime"
            self.songArtist = "Default Sting"
            self.cuePoint = 0
        }
        
        super.init()
        configure()
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let stingPlayer = try? AVAudioPlayer(contentsOf: assetURL) else { return nil }
        
        url = assetURL
        songTitle = mediaItem.title ?? "Unknown"
        songArtist = mediaItem.artist ?? "Unknown"
        cuePoint = 0
        self.stingPlayer = stingPlayer
        
        super.init()
        configure()
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let cuePoint = try container.decode(Double.self, forKey: .cuePoint)
        self.init(url: url, cuePoint: cuePoint)
    }
    
    func configure() {
        updateDelegate()
        updateOutputChannels()
        
        stingPlayer.delegate = self
        seekToCuePoint()
        
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
        seekToCuePoint()
    }
    
    func seekToCuePoint() {
        stingPlayer.currentTime = cuePoint
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
