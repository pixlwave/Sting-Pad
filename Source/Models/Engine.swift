import Foundation
import AVFoundation

class Engine {
    static let shared = Engine()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    
    var outputConfig: OutputConfig = (try? JSONDecoder().decode(OutputConfig.self, from: UserDefaults.standard.data(forKey: "outputConfig") ?? Data())) ?? .default {
        didSet {
            updateChannelMap()
            if let data = try? JSONEncoder().encode(outputConfig) { UserDefaults.standard.set(data, forKey: "outputConfig")}
        }
    }
    
    var playingSting: Sting?
    
    var totalTime: TimeInterval {
        guard let sting = playingSting else { return 0 }
        return sting.totalTime
    }
    var elapsedTime: TimeInterval {
        guard
            let sting = playingSting,
            let lastRenderTime = player.lastRenderTime,
            let elapsedSamples = player.playerTime(forNodeTime: lastRenderTime)?.sampleTime
        else { return 0 }
        return Double(elapsedSamples) / sting.audioFile.processingFormat.sampleRate
    }
    var remainingTime: TimeInterval {
        totalTime - elapsedTime
    }
    
    var isInBackground = false {
        didSet {
            switch isInBackground {
            case true:
                if playingSting == nil { engine.stop() }
            case false:
                startAudioEngine()
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
    }
    
    func startAudioEngine() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            fatalError("Could not start engine. Error: \(error).")
        }
    }
    
    func availableChannels() -> [AVAudioSessionChannelDescription] {
        return session.currentRoute.outputs.compactMap { $0.channels }.flatMap { $0 }
    }
    
    func outputChannelCount() -> Int {
        Int(engine.outputNode.outputFormat(forBus: 0).channelCount)
    }
    
    @objc func updateChannelMap() {
        let channelCount = outputChannelCount()
        
        // with 6 channels [-1, -1, 0, 1, -1, -1] would use channels 3 & 4
        var channelMap = [Int32](repeating: -1, count: channelCount)
        if outputConfig.highestChannel < channelCount {
            channelMap[outputConfig.left] = 0   // send left channel, the left stream
            channelMap[outputConfig.right] = 1   // send right channel, the right stream
            
            let propSize = UInt32(channelMap.count) * UInt32(MemoryLayout<UInt32>.size)
            let statusCode = AudioUnitSetProperty(engine.outputNode.audioUnit!, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, 1, channelMap, propSize)
        }
        
        startAudioEngine()
    }
    
    private func prepareToPlay(_ sting: Sting) {
        if player.isPlaying { player.stop() }
        
        if sting.audioFile.processingFormat != engine.mainMixerNode.inputFormat(forBus: 0) {
            engine.connect(player, to: engine.mainMixerNode, fromBus: 0, toBus: 0, format: sting.audioFile.processingFormat)
        }
    }
    
    private func scheduleSegment(of sting: Sting, from startSample: AVAudioFramePosition, for sampleCount: AVAudioFrameCount) {
        player.scheduleSegment(sting.audioFile, startingFrame: startSample, frameCount: sampleCount, at: nil, completionCallbackType: .dataPlayedBack, completionHandler: stopCompletionHandler(for: sting))
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
        guard !sting.isMissing else { return }
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
        guard length > 0 else { return }
        
        let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length)
        
        prepareToPlay(sting)
        scheduleSegment(of: sting, from: sting.startSample, for: sampleCount)
        startPlayback(of: sting)
    }
    
    func previewEnd(of sting: Sting, for length: TimeInterval = 3) {
        guard length > 0 else { return }
        
        let endSample = AVAudioFrameCount(sting.startSample) + sting.sampleCount
        if sting.loops {
            let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length) / 2
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            
            prepareToPlay(sting)
            scheduleSegment(of: sting, from: previewStartSample, for: sampleCount)
            scheduleSegment(of: sting, from: sting.startSample, for: sampleCount)
            startPlayback(of: sting)
        } else {
            let sampleCount = AVAudioFrameCount(sting.audioFile.processingFormat.sampleRate * length)
            let previewStartSample = AVAudioFramePosition(endSample - sampleCount)
            
            prepareToPlay(sting)
            scheduleSegment(of: sting, from: previewStartSample, for: sampleCount)
            startPlayback(of: sting)
        }
    }
    
}


protocol PlaybackDelegate: AnyObject {
    func stingDidStartPlaying(_ sting: Sting)
    func stingDidStopPlaying(_ sting: Sting)
}
