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
    var stings: [Sting] {
        didSet {
            let channels = currentChannels()
            if channels.count > 3 { useOutput(channels: [channels[2], channels[3]]) }; #warning("Handle this for each new player.")
            NotificationCenter.default.post(Notification(name: Notification.Name("Stings Did Change")))
        }
    }
    
    private var playingSting = 0
    
    init() {
        // load stings from user defaults
        if let data = UserDefaults.standard.data(forKey: "Stings"), let array = try? JSONDecoder().decode([Sting].self, from: data) {
            stings = array
        } else {
            stings = [Sting]()
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
    
    func addSting() {
        stings.append(Sting(url: Sting.defaultURL, cuePoint: 0))
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
    
    func save() {
        guard let jsonData = try? JSONEncoder().encode(stings) else { return }
        UserDefaults.standard.set(jsonData, forKey: "Stings")
    }
    
}
