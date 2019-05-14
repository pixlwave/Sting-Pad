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
    var stings = [Sting]()
    
    private var playingSting = 0
    
    init() {
        for i in 0..<5 {
            let url = UserDefaults.standard.url(forKey: "StingURL\(i)") ?? Sting.defaultURL
            let title = UserDefaults.standard.string(forKey: "StingTitle\(i)") ?? "Chime"
            let artist = UserDefaults.standard.string(forKey: "StingArtist\(i)") ?? "Default Sting"
            let cuePoint = UserDefaults.standard.double(forKey: "StingCuePoint\(i)")
            stings.append(Sting(url: url, title: title, artist: artist, cuePoint: cuePoint))
        }
        
        // listen for iPod playback changes
        musicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateDidChange(_:)), name:  .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
    }
    
    func currentChannels() -> [AVAudioSessionChannelDescription] {
        return session.currentRoute.outputs.compactMap { $0.channels }.flatMap { $0 }
    }
    
    func enableMultiRoutes() {
        // allow music to play whilst muted with playback category
        // prevent app launch from killing iPod by allowing mixing
        do {
            try session.setCategory(.multiRoute, options: .mixWithOthers)
            try session.setActive(true)
            let channels = currentChannels()
            if channels.count > 3 {
                useOutput(channels: [channels[2], channels[3]])
            }
        } catch {
            print("Error: \(error)"); #warning("Implement error handling")
        }
    }
    
    func useOutput(channels: [AVAudioSessionChannelDescription]) {
        for sting in stings {
            sting.useOutput(channels: channels)
        }
    }
    
    func playSting(_ selectedSting: Int) {
        if !isMultiRoute { musicPlayer.pause() }
        if selectedSting != playingSting { stings[playingSting].stop() }
        stings[selectedSting].play()
        playingSting = selectedSting
    }
    
    func stopSting() {
        stings[playingSting].stop()
    }
    
    @objc func playbackStateDidChange(_ notification: Notification) {
        if !isMultiRoute {
            #warning("Handle music player starts playing on single output")
        }
    }
    
    func playiPod() {
        if !isMultiRoute { stings[playingSting].stop() }
        musicPlayer.play()
    }
    
    func pauseiPod() {
        musicPlayer.pause()
    }
    
    func setStingDelegates(_ delegate: StingDelegate) {
        for sting in stings {
            sting.delegate = delegate
        }
    }
    
}
