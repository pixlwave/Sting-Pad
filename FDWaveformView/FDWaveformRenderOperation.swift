//
// Copyright 2013 - 2017, William Entriken and the FDWaveformView contributors.
//
import UIKit
import AVFoundation
import Accelerate

/// Single wave data made from multiple audio samples
struct WaveformSample {
    var min: Float = 0
    var max: Float = 0
}

/// Format options for FDWaveformRenderOperation
//MAYBE: Make this public
struct FDWaveformRenderFormat {
    
    /// The color of the waveform
    internal var wavesColor: UIColor
    
    /// The scale factor to apply to the rendered image (usually the current screen's scale)
    public var scale: CGFloat
    
    /// Whether the resulting image size should be as close as possible to imageSize (approximate)
    /// or whether it should match it exactly. Right now there is no support for matching exactly.
    // TODO: Support rendering operations that always match the desired imageSize passed in.
    //       Right now the imageSize passed in to the render operation might not match the
    //       resulting image's size. This flag is hard coded here to convey that.
    public let constrainImageSizeToExactlyMatch = false
    
    // To make these public, you must implement them
    // See http://stackoverflow.com/questions/26224693/how-can-i-make-public-by-default-the-member-wise-initialiser-for-structs-in-swif
    public init() {
        self.init(wavesColor: .black, scale: UIScreen.main.scale)
    }
    
    init(wavesColor: UIColor, scale: CGFloat) {
        self.wavesColor = wavesColor
        self.scale = scale
    }
}

/// Operation used for rendering waveform images
final public class FDWaveformRenderOperation: Operation {
    
    /// The audio context used to build the waveform
    let audioContext: FDAudioContext
    
    /// Size of waveform image to render
    public let imageSize: CGSize
    
    /// Range of samples within audio asset to build waveform for
    public let sampleRange: CountableRange<Int>
    
    /// Format of waveform image
    let format: FDWaveformRenderFormat
    
    // MARK: - NSOperation Overrides
    
    public override var isAsynchronous: Bool { return true }
    
    private var _isExecuting = false
    public override var isExecuting: Bool { return _isExecuting }
    
    private var _isFinished = false
    public override var isFinished: Bool { return _isFinished }
    
    // MARK: - Private
    
    ///  Handler called when the rendering has completed. nil UIImage indicates that there was an error during processing.
    private let completionHandler: (UIImage?) -> ()
    
    /// Final rendered image. Used to hold image for completionHandler.
    private var renderedImage: UIImage?
    
    init(audioContext: FDAudioContext, imageSize: CGSize, sampleRange: CountableRange<Int>? = nil, format: FDWaveformRenderFormat = FDWaveformRenderFormat(), completionHandler: @escaping (_ image: UIImage?) -> ()) {
        self.audioContext = audioContext
        self.imageSize = imageSize
        self.sampleRange = sampleRange ?? 0..<audioContext.totalSamples
        self.format = format
        self.completionHandler = completionHandler
        
        super.init()
        
        self.completionBlock = { [weak self] in
            guard let `self` = self else { return }
            self.completionHandler(self.renderedImage)
            self.renderedImage = nil
        }
    }
    
    public override func start() {
        guard !isExecuting && !isFinished && !isCancelled else { return }
        
        willChangeValue(forKey: "isExecuting")
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
        
        if #available(iOS 8.0, *) {
            DispatchQueue.global(qos: .background).async { self.render() }
        } else {
            DispatchQueue.global(priority: .background).async { self.render() }
        }
    }
    
    private func finish(with image: UIImage?) {
        guard !isFinished && !isCancelled else { return }
        
        renderedImage = image
        
        // completionBlock called automatically by NSOperation after these values change
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _isExecuting = false
        _isFinished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
    
    private func render() {
        guard
            !sampleRange.isEmpty,
            imageSize.width > 0, imageSize.height > 0
            else {
                finish(with: nil)
                return
        }
        
        let targetSamples = Int(imageSize.width * format.scale)
        
        let image: UIImage? = {
            guard
                let waveformData = sliceAsset(withRange: sampleRange, andDownsampleTo: targetSamples),
                let image = plotWaveformGraph(waveformData)
                else { return nil }
            
            return image
        }()
        
        finish(with: image)
    }
    
    /// Read the asset and create create a lower resolution set of samples
    func sliceAsset(withRange slice: CountableRange<Int>, andDownsampleTo targetSamples: Int) -> [WaveformSample]? {
        guard !isCancelled else { return nil }
        
        guard
            !slice.isEmpty,
            targetSamples > 0,
            let reader = try? AVAssetReader(asset: audioContext.asset)
            else { return nil }
        
        reader.timeRange = CMTimeRange(start: CMTime(value: Int64(slice.lowerBound), timescale: audioContext.asset.duration.timescale),
                                       duration: CMTime(value: Int64(slice.count), timescale: audioContext.asset.duration.timescale))
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioContext.assetTrack, outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        let formatDescriptions = audioContext.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else { return nil }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        let samplesPerPixel = max(1, channelCount * slice.count / targetSamples)
        var outputSamples = [WaveformSample]()
        
        reader.startReading()
        defer { reader.cancelReading() } // Cancel reading if we exit early if operation is cancelled
        
        while reader.status == .reading {
            guard !isCancelled else { return nil }
            
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                    break
            }
            
            let readBufferLength = CMBlockBufferGetDataLength(readBuffer)
            var audioData = [Float](repeating: 0.0, count: readBufferLength / 4)
            CMBlockBufferCopyDataBytes(readBuffer, atOffset: 0, dataLength: readBufferLength, destination: &audioData)
            
            let samples = waveformData(for: audioData, with: samplesPerPixel)
            outputSamples.append(contentsOf: samples)
        }
        
        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        // Something went wrong. Handle it, or not depending on if you can get above to work
        if reader.status == .completed || true {
            return outputSamples
        } else {
            print("FDWaveformRenderOperation failed to read audio: \(String(describing: reader.error))")
            return nil
        }
    }
    
    func waveformData(for audioData: [Float], with audioSamplesPerWave: Int) -> [WaveformSample] {
        var waveformData = [WaveformSample]()
        
        for chunk in audioData.chunked(into: audioSamplesPerWave) {
            var waveformSample = WaveformSample()
            vDSP_maxv(chunk, 1, &waveformSample.max, vDSP_Length(chunk.count))
            vDSP_minv(chunk, 1, &waveformSample.min, vDSP_Length(chunk.count))
            waveformData.append(waveformSample)
        }
        
        return waveformData
    }
    
    // TODO: report progress? (for issue #2)
    func plotWaveformGraph(_ samples: [WaveformSample]) -> UIImage? {
        guard !isCancelled else { return nil }
        
        let imageSize = CGSize(width: CGFloat(samples.count) / format.scale,
                               height: self.imageSize.height)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, format.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            NSLog("FDWaveformView failed to get graphics context")
            return nil
        }
        context.scaleBy(x: 1 / format.scale, y: 1 / format.scale) // Scale context to account for scaling applied to image
        context.setShouldAntialias(false)
        context.setAlpha(1.0)
        context.setLineWidth(1.0 / format.scale)
        context.setStrokeColor(format.wavesColor.cgColor)
        
        let sampleDrawingScale = Float(0.5 * imageSize.height * format.scale)
        
        let verticalMiddle = (imageSize.height * format.scale) / 2
        for (x, sample) in samples.enumerated() {
            context.move(to: CGPoint(x: CGFloat(x), y: verticalMiddle + CGFloat(sample.min * sampleDrawingScale)))
            context.addLine(to: CGPoint(x: CGFloat(x), y: verticalMiddle + CGFloat(sample.max * sampleDrawingScale)))
            context.strokePath();
        }
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            NSLog("FDWaveformView failed to get waveform image from context")
            return nil
        }
        
        return image
    }
}

extension AVAssetReader.Status : CustomStringConvertible{
    public var description: String{
        switch self{
        case .reading: return "reading"
        case .unknown: return "unknown"
        case .completed: return "completed"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        @unknown default:
            fatalError()
        }
    }
}

