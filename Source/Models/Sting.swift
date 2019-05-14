import Foundation
import AVFoundation
import MediaPlayer

class Sting: NSObject, Codable {
    static let defaultURL = URL(fileURLWithPath: Bundle.main.path(forResource: "ComputerMagic", ofType: "m4a")!)
    
    var delegate: StingDelegate?
    
    var url: URL
    var title: String
    var artist: String
    private(set) var cuePoint: Double; #warning("This is public get to archive, but should probs be computed?")
    
    private let stingPlayer: AVAudioPlayer
    
    enum CodingKeys: String, CodingKey {
        case url
        case cuePoint
    }
    
    init(url: URL, cuePoint: Double) {
        #warning("Implement loading title & artist from url")
        if let stingPlayer = try? AVAudioPlayer(contentsOf: url) {
            self.url = url
            self.title = "TO BE IMPLEMENTED"
            self.artist = "TO BE IMPLEMENTED"
            self.cuePoint = cuePoint
            self.stingPlayer = stingPlayer
        } else {    #warning("Test this as a fallthrough case")
            self.url = Sting.defaultURL
            self.stingPlayer = try! AVAudioPlayer(contentsOf: self.url)
            self.title = "Chime"
            self.artist = "Default Sting"
            self.cuePoint = 0
        }
        
        super.init()
        
        self.stingPlayer.delegate = self
        self.stingPlayer.numberOfLoops = 0  // needed?
        self.stingPlayer.currentTime = cuePoint
        self.stingPlayer.prepareToPlay()
    }
    
    init?(mediaItem: MPMediaItem) {
        guard let assetURL = mediaItem.assetURL, let stingPlayer = try? AVAudioPlayer(contentsOf: assetURL) else { return nil }
        
        url = assetURL
        title = mediaItem.title ?? "Unknown"
        artist = mediaItem.artist ?? "Unknown"
        cuePoint = 0
        self.stingPlayer = stingPlayer
        
        super.init()
        
        stingPlayer.delegate = self
        stingPlayer.numberOfLoops = 0 // needed?
        stingPlayer.currentTime = cuePoint
        stingPlayer.prepareToPlay()
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let url = try container.decode(URL.self, forKey: .url)
        let cuePoint = try container.decode(Double.self, forKey: .cuePoint)
        self.init(url: url, cuePoint: cuePoint)
    }
    
    func useOutput(channels: [AVAudioSessionChannelDescription]) {
        stingPlayer.channelAssignments = channels
    }
    
    func play() {
        stingPlayer.play()
        delegate?.stingDidStartPlaying(self)
    }
    
    func stop() {
        stingPlayer.stop()
        stingPlayer.currentTime = cuePoint
        stingPlayer.prepareToPlay()
        delegate?.stingDidStopPlaying(self)
    }
    
    func setCue(_ cuePoint: Double) {
        self.cuePoint = cuePoint * stingPlayer.duration
        stingPlayer.currentTime = self.cuePoint
        stingPlayer.prepareToPlay()
    }
    
    func getCue() -> Double {
        return cuePoint / stingPlayer.duration
    }
    
}

extension Sting: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.stingDidStopPlaying(self)
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        delegate?.stingDidStopPlaying(self)
    }
}

protocol StingDelegate {
    func stingDidStartPlaying(_ sting: Sting)
    func stingDidStopPlaying(_ sting: Sting)
}
