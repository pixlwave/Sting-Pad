import UIKit

class WaveformView: FDWaveformView {
    
    var startMarkerLine = UIView()
    var endMarkerLine = UIView()
    
    override func setup() {
        super.setup()
        addSubview(startMarkerLine)
        addSubview(endMarkerLine)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        NotificationCenter.default.post(Notification(name: .waveformViewDidLayoutSubviews))
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        startMarkerLine.backgroundColor = tintColor
        endMarkerLine.backgroundColor = tintColor
    }
    
    func position(of sample: Int) -> CGFloat? {
        let ratio = bounds.width / CGFloat(zoomSamples.count)
        let position = CGFloat(sample - zoomSamples.lowerBound) * ratio
        return (0...bounds.width).contains(position) ? position : nil
    }
    
    var startPosition: CGFloat? {
        position(of: highlightedSamples?.lowerBound ?? 0)
    }
    
    var endPosition: CGFloat? {
        position(of: highlightedSamples?.upperBound ?? totalSamples)
    }
    
    func sample(for position: CGFloat) -> Int {
        let ratio = CGFloat(zoomSamples.count) / bounds.width
        let sample = zoomSamples.lowerBound + Int(position * ratio)
        return min(max(0, sample), totalSamples)
    }
    
    // prevents the pinch and pan gestures recognising with the gesture to dismiss the card style modal
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizers?.contains(otherGestureRecognizer) ?? false
    }
    
}
