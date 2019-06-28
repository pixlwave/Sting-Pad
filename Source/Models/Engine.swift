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
    
    var indexOfPlayingSting: Int? { return isPlaying ? lastPlayedStingIndex : nil }
    private var lastPlayedStingIndex = -1
    private var isPlaying: Bool {
        guard player.isPlaying else { return false }
        let buffer = show.stings[lastPlayedStingIndex].buffer
        
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerPosition = player.playerTime(forNodeTime: lastRenderTime)?.sampleTime
        else { return true }
        
        // fix player.isPlaying returning true in the completion handler
        return playerPosition < AVAudioFramePosition(buffer.frameLength)
    }
    
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
        engine.connect(player, to: mixer, fromBus: 0, toBus: 0, format: outputHWFormat)
        
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
        let channelCount = Int(engine.outputNode.outputFormat(forBus: 0).channelCount)
        
        // with 6 channels [-1, -1, 0, 1, -1, -1] would use channels 3 & 4
        var channelMap = [Int32](repeating: -1, count: channelCount)
        if channelCount > 3 {
            channelMap[2] = 0   // left out 3
            channelMap[3] = 1   // right out 4
            
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
        
        if sting.buffer.format != engine.mainMixerNode.inputFormat(forBus: 0) {
            engine.connect(player, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: sting.buffer.format)
        }
        
        player.scheduleBuffer(sting.buffer, at: nil, options: options) {
            self.playbackDelegate?.stingDidStopPlaying(at: index)
        }
        
        player.play()
        lastPlayedStingIndex = index
        playbackDelegate?.stingDidStartPlaying(at: index)
    }
    
    func stopSting() {
        player.stop()
        playbackDelegate?.stingDidStopPlaying(at: lastPlayedStingIndex)
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
