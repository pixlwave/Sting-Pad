import Foundation
import AVFoundation
import MediaPlayer

class Sting: NSObject {
    static let defaultURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("ComputerMagic", ofType: "m4a")!)
    
    var delegate: StingDelegate?
    
    var url: NSURL
    var title: String
    var artist: String
    private(set) var cuePoint: Double // TODO: This is public get to archive, but should probs be computed?
    lazy var waveform = FDWaveformView(frame: CGRect.zero)
    
    private var stingPlayer: AVAudioPlayer!
    
    init(url: NSURL, title: String, artist: String, cuePoint: Double) {
    
        // TODO: load title & artist from url
        if let stingPlayer = try? AVAudioPlayer(contentsOfURL: url) {
            self.url = url
            self.title = title
            self.artist = artist
            self.cuePoint = cuePoint
            self.stingPlayer = stingPlayer
        } else {    // TODO: Test this as a fallthrough case
            self.url = Sting.defaultURL
            self.stingPlayer = try? AVAudioPlayer(contentsOfURL: self.url)
            self.title = "Chime"
            self.artist = "Default Sting"
            self.cuePoint = 0
        }
        
        super.init()
    
        self.stingPlayer.delegate = self
        self.stingPlayer.numberOfLoops = 0  // needed?
        self.stingPlayer.currentTime = cuePoint
        self.stingPlayer.prepareToPlay()
        
        waveform.audioURL = self.url
        waveform.doesAllowScrubbing = true
        // waveform.doesAllowStretchAndScroll = true
        waveform.wavesColor = UIColor.blueColor()
        waveform.progressColor = UIColor.whiteColor()
        waveform.progressSamples = UInt(Double(waveform.totalSamples) * getCue())
    
    }
    
    func play() {
        stingPlayer.play()
    }
    
    func stop() {
        stingPlayer.stop()
        stingPlayer.currentTime = cuePoint
        stingPlayer.prepareToPlay()
    }
    
    func loadSting(mediaItem: MPMediaItem) {
        url = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as! NSURL
        
        stingPlayer = try? AVAudioPlayer(contentsOfURL: url)
        stingPlayer.delegate = self
        stingPlayer.numberOfLoops = 0 // needed?
        
        cuePoint = 0
        stingPlayer.currentTime = cuePoint
        stingPlayer.prepareToPlay()
        
        title = mediaItem.valueForProperty(MPMediaItemPropertyTitle) as! String
        artist = mediaItem.valueForProperty(MPMediaItemPropertyArtist) as! String
    }
    
    func setCue(cuePoint: Double) {
        self.cuePoint = cuePoint * stingPlayer.duration
        stingPlayer.currentTime = self.cuePoint
        stingPlayer.prepareToPlay()
    }
    
    func getCue() -> Double {
        return cuePoint / stingPlayer.duration
    }
    
}

extension Sting: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        delegate?.stingHasStopped(self)
    }
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        delegate?.stingHasStopped(self)
    }
}

protocol StingDelegate {
    func stingHasStopped(sting: Sting)
}