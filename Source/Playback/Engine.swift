import Foundation
import AVFoundation
import os.log

class Engine {
    static let shared = Engine()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    
    var outputConfig: ChannelPair = (try? JSONDecoder().decode(ChannelPair.self, from: UserDefaults.standard.data(forKey: "outputConfig") ?? Data())) ?? .default {
        didSet {
            updateChannelMap()
            if let data = try? JSONEncoder().encode(outputConfig) { UserDefaults.standard.set(data, forKey: "outputConfig") }
        }
    }
    
    var playingSting: Sting?
    
    var totalTime: TimeInterval {
        guard let sting = playingSting else { return 0 }
        return sting.totalTime
    }
    var elapsedTime: TimeInterval {
        guard
            let audioFile = playingSting?.audioFile,
            let lastRenderTime = player.lastRenderTime,
            let elapsedSamples = player.playerTime(forNodeTime: lastRenderTime)?.sampleTime
        else { return 0 }
        return Double(elapsedSamples) / audioFile.processingFormat.sampleRate
    }
    
    var isInBackground = false {
        didSet {
            switch isInBackground {
            case true:
                if playingSting == nil { engine.stop() }
            case false:
                configureAudioSession()
                updateChannelMap()
            }
        }
    }
    
    var playbackDelegate: PlaybackDelegate?
    
    init() {
        configureAudioSession()
        configureEngine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateChannelMap), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    func configureAudioSession() {
        // allow music to play whilst muted with playback category
        // prevent app launch from killing iPod by allowing mixing
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            #warning("Implement error handling")
            os_log("Error configuring audio session: %@", String(describing: error))
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
    }
    
    func ensureEngineIsRunning() -> Bool {
        guard !engine.isRunning else { return true }
        do {
            try engine.start()
        } catch {
            os_log("Error starting audio engine: %@", String(describing: error))
            return false
        }
        
        return true
    }
    
    func audioInterfaceName() -> String {
        return session.currentRoute.outputs.first?.portName ?? "Audio Interface"
    }
    
    func outputChannelCount() -> Int {
        Int(engine.outputNode.outputFormat(forBus: 0).channelCount)
    }
    
    @objc func updateChannelMap() {
        guard let audioUnit = engine.outputNode.audioUnit else { return }
        
        let channelCount = outputChannelCount()
        
        // with 6 channels [-1, -1, 0, 1, -1, -1] would use channels 3 & 4
        var channelMap = [Int32](repeating: -1, count: channelCount)
        if outputConfig.highestChannel < channelCount {
            channelMap[outputConfig.left] = 0   // send left channel, the left stream
            channelMap[outputConfig.right] = 1   // send right channel, the right stream
            
            let propSize = UInt32(channelMap.count) * UInt32(MemoryLayout<UInt32>.size)
            _ = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, 1, channelMap, propSize)
        } else {
            _ = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, 1, nil, 0)
        }
        
        if playingSting != nil { _ = ensureEngineIsRunning() }
    }
    
    private func prepareToPlay(_ sting: Sting) -> Bool {
        guard let audioFile = sting.audioFile else { return false }
        if player.isPlaying { player.stop() }
        
        if audioFile.processingFormat != engine.mainMixerNode.inputFormat(forBus: 0) {
            engine.connect(player, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: audioFile.processingFormat)
        }
        
        return ensureEngineIsRunning()
    }
    
    private func scheduleSegment(of sting: Sting, from startSample: AVAudioFramePosition, for sampleCount: AVAudioFrameCount) {
        guard let audioFile = sting.audioFile else { return }
        player.scheduleSegment(audioFile, startingFrame: startSample, frameCount: sampleCount, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: stopCompletionHandler(for: sting))
    }
    
    private func schedule(_ buffer: AVAudioPCMBuffer, for sting: Sting, options: AVAudioPlayerNodeBufferOptions = []) {
        player.scheduleBuffer(buffer, at: nil, options: options, completionCallbackType: .dataPlayedBack, completionHandler: stopCompletionHandler(for: sting))
    }
    
    private func stopCompletionHandler(for sting: Sting) -> (AVAudioPlayerNodeCompletionCallbackType) -> Void {
        { callbackType in
            self.playingSting = nil
            self.playbackDelegate?.stingDidStopPlaying(sting)
            if self.isInBackground { self.engine.stop() }
        }
    }
    
    private func startPlayback(of sting: Sting) {
        player.play()
        playingSting = sting
        playbackDelegate?.stingDidStartPlaying(sting)
    }
    
    func play(_ sting: Sting) {
        guard prepareToPlay(sting) else { return }
        
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
        guard let audioFile = sting.audioFile, length > 0 else { return }
        guard prepareToPlay(sting) else { return }
        
        let sampleCount = AVAudioFrameCount(audioFile.processingFormat.sampleRate * length)
        
        scheduleSegment(of: sting, from: sting.startSample, for: sampleCount)
        startPlayback(of: sting)
    }
    
    func previewEnd(of sting: Sting, for length: TimeInterval = 3) {
        guard let audioFile = sting.audioFile, length > 0 else { return }
        guard prepareToPlay(sting) else { return }
        
        let endSample = AVAudioFrameCount(sting.startSample) + sting.sampleCount
        if sting.loops {
            let sampleCount = AVAudioFrameCount(audioFile.processingFormat.sampleRate * length) / 2
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            
            scheduleSegment(of: sting, from: previewStartSample, for: sampleCount)
            scheduleSegment(of: sting, from: sting.startSample, for: sampleCount)
            startPlayback(of: sting)
        } else {
            let sampleCount = AVAudioFrameCount(audioFile.processingFormat.sampleRate * length)
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            
            scheduleSegment(of: sting, from: previewStartSample, for: sampleCount)
            startPlayback(of: sting)
        }
    }
    
}


protocol PlaybackDelegate: AnyObject {
    func stingDidStartPlaying(_ sting: Sting)
    func stingDidStopPlaying(_ sting: Sting)
}
