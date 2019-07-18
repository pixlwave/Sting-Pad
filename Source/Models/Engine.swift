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
    
    var playingSting: Sting?
    private var isPlaying: Bool {
        guard player.isPlaying else { return false }
        guard let sting = playingSting else { return false }
        
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerPosition = player.playerTime(forNodeTime: lastRenderTime)?.sampleTime
        else { return true }
        
        // fix player.isPlaying returning true in the completion handler
        return playerPosition < AVAudioFramePosition(sting.sampleCount)
    }
    
    var totalTime: TimeInterval {
        guard let sting = playingSting else { return 0 }
        return Double(sting.sampleCount) / sting.audioFile.processingFormat.sampleRate
    }
    var elapsedTime: TimeInterval {
        guard
            let sting = playingSting,
            let lastRenderTime = player.lastRenderTime,
            let elapsedSamples = player.playerTime(forNodeTime: lastRenderTime)?.sampleTime
        else { return 0 }
        return Double(elapsedSamples) / sting.audioFile.processingFormat.sampleRate
    }
    var remainingTime: TimeInterval { return totalTime - elapsedTime }
    
    var playbackDelegate: PlaybackDelegate?
    
    init() {
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
            fatalError("Could not start engine. Error: \(error).")
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
    
    private func prepareToPlay(_ sting: Sting) {
        if !isMultiRoute { musicPlayer.pause() }
        if player.isPlaying { player.stop() }
        
        if sting.audioFile.processingFormat != engine.mainMixerNode.inputFormat(forBus: 0) {
            engine.connect(player, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: sting.audioFile.processingFormat)
        }
    }
    
    private func scheduleSegment(of sting: Sting, from startSample: AVAudioFramePosition, for sampleCount: AVAudioFrameCount) {
        player.scheduleSegment(sting.audioFile, startingFrame: startSample, frameCount: sampleCount, at: nil) {
            self.playbackDelegate?.stingDidStopPlaying(sting)
            self.playingSting = nil
        }
    }
    
    private func schedule(_ buffer: AVAudioPCMBuffer, for sting: Sting, options: AVAudioPlayerNodeBufferOptions = []) {
        player.scheduleBuffer(buffer, at: nil, options: options) {
            self.playbackDelegate?.stingDidStopPlaying(sting)
            self.playingSting = nil
        }
    }
    
    private func startPlayback(of sting: Sting) {
        player.play()
        playingSting = sting
        playbackDelegate?.stingDidStartPlaying(sting)
    }
    
    func play(_ sting: Sting) {
        prepareToPlay(sting)
        
        if sting.loops {
            guard let buffer = sting.buffer else { return }
            schedule(buffer, for: sting, options: .loops)
        } else {
            scheduleSegment(of: sting, from: sting.startSample, for: sting.sampleCount)
        }
        
        startPlayback(of: sting)
    }
    
    func stopSting() {
        player.stop()   // delegate method is called by the player
    }
    
    func previewStart(of sting: Sting, for length: TimeInterval = 3) {
        let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length)
        
        prepareToPlay(sting)
        scheduleSegment(of: sting, from: sting.startSample, for: sampleCount)
        startPlayback(of: sting)
    }
    
    func previewEnd(of sting: Sting, for length: TimeInterval = 3) {
        let endSample = AVAudioFrameCount(sting.startSample) + sting.sampleCount
        if sting.loops {
            let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length) / 2
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            #warning("Needs implementing")
        } else {
            let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length)
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            
            prepareToPlay(sting)
            scheduleSegment(of: sting, from: previewStartSample, for: sampleCount)
            startPlayback(of: sting)
        }
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
    func stingDidStartPlaying(_ sting: Sting)
    func stingDidStopPlaying(_ sting: Sting)
}
