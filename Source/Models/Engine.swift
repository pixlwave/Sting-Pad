import Foundation
import AVFoundation
import MediaPlayer

class Engine {
    static let shared = Engine()
    
    #warning("Listen for multiroute notifications")
    #warning("Handle false")
    private let session = AVAudioSession.sharedInstance()
    private var isMultiRoute = true
    
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var show: ShowDocument
    
    private var playingSting = 0
    
    init() {
        #warning("Test whether file exists after initialising document?")
        if FileManager.default.fileExists(atPath: ShowDocument.defaultURL.path) {
            show = ShowDocument(fileURL: ShowDocument.defaultURL)
            show.open()
        } else {
            show = ShowDocument(fileURL: ShowDocument.defaultURL)
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
    
    func addSting() {
        show.stings.append(Sting(url: Sting.defaultURL, cuePoint: 0))
    }
    
    func playSting(_ selectedSting: Int) {
        if !isMultiRoute { musicPlayer.pause() }
        if selectedSting != playingSting { show.stings[playingSting].stop() }
        show.stings[selectedSting].play()
        playingSting = selectedSting
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
    
    func setStingDelegates(_ delegate: StingDelegate) {
        for sting in show.stings {
            sting.delegate = delegate
        }
    }
    
}
