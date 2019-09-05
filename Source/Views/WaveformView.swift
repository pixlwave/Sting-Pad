import UIKit

class WaveformView: FDWaveformView {
    
    override var zoomSamples: CountableRange<Int> {
        didSet { NotificationCenter.default.post(Notification(name: .waveformViewDidUpdate)) }
    }
    
    override var highlightedSamples: CountableRange<Int>? {
        didSet { NotificationCenter.default.post(Notification(name: .waveformViewDidUpdate)) }
    }
    
    func position(of sample: Int) -> CGFloat {
        let ratio = frame.width / CGFloat(zoomSamples.count)
        return CGFloat(sample - zoomSamples.lowerBound) * ratio
    }
    
}
