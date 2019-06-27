import Foundation
import AVFoundation
import MediaPlayer

class Engine {
    static let shared = Engine()
    
    #warning("Listen for multiroute notifications")
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    private var isMultiRoute = true
    
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var show: ShowDocument
    
    private var playingStingIndex = 0
    var playbackDelegate: PlaybackDelegate?
    
    init() {
        show = ShowDocument(fileURL: ShowDocument.defaultURL)
        
        if FileManager.default.fileExists(atPath: show.fileURL.path) {
            show.open()
        } else {
            show.save(to: show.fileURL, for: .forCreating)
        }
        
        configureAudioSession()
        configureEngine()
        
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
    
    func configureEngine() {
        // get output hardware format
        let output = engine.outputNode
        let outputHWFormat = output.outputFormat(forBus: 0)
        
        // connect mixer to output
        let mixer = engine.mainMixerNode
        #warning("Only needed if using non-default output")
        engine.connect(mixer, to: output, format: outputHWFormat)
        
        // attach the player to the engine
        engine.attach(player)
        engine.connect(player, to: mixer, format: outputHWFormat);  #warning("Format needs to be standardised, or tracked with each buffer played")
        
        updateChannelMap()
        
        do {
            try engine.start()
        } catch {
            fatalError("Could not start engine. error: \(error).")
        }
    }
    
    func availableChannels() -> [AVAudioSessionChannelDescription] {
        return session.currentRoute.outputs.compactMap { $0.channels }.flatMap { $0 }
    }
    
    func updateChannelMap() {
        if availableChannels().count > 3 {
            let channelMapA: [Int32] = [0, 1, -1, -1]   // left out 1, right out 2
            let channelMapB: [Int32] = [-1, -1, 0, 1]   // left out 3, right out 4
            let channelMap = channelMapB
            
            let propSize = UInt32(channelMap.count) * UInt32(MemoryLayout<UInt32>.size)
            let statusCode = AudioUnitSetProperty(engine.inputNode.audioUnit!, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, 1, channelMap, propSize)
            print(statusCode)
            
            #warning("Restart engine?")
        }
    }
    
    func newShow() {
        show.stings = [Sting]()
    }
    
    func add(_ sting: Sting) {
        show.stings.append(sting)
    }
    
    func playSting(at index: Int) {
        if !isMultiRoute { musicPlayer.pause() }
        if player.isPlaying { player.stop() }
        
        let sting = show.stings[index]
        let options: AVAudioPlayerNodeBufferOptions = sting.loops ? [.loops] : []
        
        player.scheduleBuffer(sting.buffer, at: nil, options: options) {
            self.playbackDelegate?.stingDidStopPlaying(at: index)
        }
        
        player.play()
        playingStingIndex = index
        playbackDelegate?.stingDidStartPlaying(at: index)
    }
    
    func stopSting() {
        player.stop()
        playbackDelegate?.stingDidStopPlaying(at: playingStingIndex)
    }
    
    @objc func playbackStateDidChange(_ notification: Notification) {
        if !isMultiRoute {
            #warning("Handle music player starts playing on single output")
        }
    }
    
    func playiPod() {
        if !isMultiRoute { stopSting() }
        musicPlayer.play()
    }
    
    func pauseiPod() {
        musicPlayer.pause()
    }
    
}


protocol PlaybackDelegate: AnyObject {
    func stingDidStartPlaying(at index: Int)
    func stingDidStopPlaying(at index: Int)
}
