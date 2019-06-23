import Foundation
import AVFoundation
import MediaPlayer

class Engine {
    static let shared = Engine()
    
    #warning("Listen for multiroute notifications")
    private let session = AVAudioSession.sharedInstance()
    private var isMultiRoute = true
    
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var show: ShowDocument
    
    private var playingSting = 0
    var stingDelegate: StingDelegate? { didSet { NotificationCenter.default.post(Notification(name: .stingDelegateDidChange)) } }
    
    init() {
        show = ShowDocument(fileURL: ShowDocument.defaultURL)
        
        if FileManager.default.fileExists(atPath: show.fileURL.path) {
            show.open()
        } else {
            show.save(to: show.fileURL, for: .forCreating)
        }
        
        configureAudioSession()
        
        // listen for iPod playback changes
        musicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateDidChange(_:)), name:  .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
    }
    
    func configureAudioSession() {
        // allow music to play whilst muted with playback category
        // prevent app launch from killing iPod by allowing mixing
        do {
            try session.setCategory(.multiRoute, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("Error: \(error)"); #warning("Implement error handling")
        }
    }
    
    func availableChannels() -> [AVAudioSessionChannelDescription] {
        return session.currentRoute.outputs.compactMap { $0.channels }.flatMap { $0 }
    }
    
    func outputChannels() -> [AVAudioSessionChannelDescription]? {
        let channels = availableChannels()
        guard channels.count > 3 else { return nil }
        return [channels[2], channels[3]]
    }
    
    func newShow() {
        show.stings = [Sting]()
    }
    
    func add(_ sting: Sting) {
        show.stings.append(sting)
    }
    
    func playSting(_ selectedSting: Int) {
        if !isMultiRoute { musicPlayer.pause() }
        if selectedSting != playingSting { show.stings[playingSting].stop() }
        show.stings[selectedSting].play()
        playingSting = selectedSting
    }
    
    func rewindSting(_ selectedSting: Int) {
        show.stings[selectedSting].seekToStart()
    }
    
    func stopSting() {
        show.stings[playingSting].stop()
    }
    
    @objc func playbackStateDidChange(_ notification: Notification) {
        if !isMultiRoute {
            #warning("Handle music player starts playing on single output")
        }
    }
    
    func playiPod() {
        if !isMultiRoute { show.stings[playingSting].stop() }
        musicPlayer.play()
    }
    
    func pauseiPod() {
        musicPlayer.pause()
    }
    
}
