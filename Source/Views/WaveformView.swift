import UIKit

class WaveformView: FDWaveformView {
    
    override var zoomSamples: CountableRange<Int> {
        didSet { NotificationCenter.default.post(Notification(name: .waveformViewDidUpdate)) }
    }
    
    override var highlightedSamples: CountableRange<Int>? {
        didSet { NotificationCenter.default.post(Notification(name: .waveformViewDidUpdate)) }
    }
    
    let startMarker = WaveformMarkerView()
    let endMarker = WaveformMarkerView()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        startMarker.dragRecogniser.addTarget(self, action: #selector(startMarkerDragged(_:)))
        endMarker.dragRecogniser.addTarget(self, action: #selector(endMarkerDragged(_:)))
        
        addSubview(startMarker)
        addSubview(endMarker)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let startSample = highlightedSamples?.lowerBound, let x = position(of: startSample) {
            startMarker.isHidden = false
            startMarker.frame = CGRect(x: x - startMarker.width / 2, y: 0, width: startMarker.width, height: frame.height)
        } else {
            startMarker.isHidden = true
        }
        
        if let endSample = highlightedSamples?.upperBound, let x = position(of: endSample) {
            endMarker.isHidden = false
            endMarker.frame = CGRect(x: x - endMarker.width / 2, y: 0, width: endMarker.width, height: frame.height)
        } else {
            endMarker.isHidden = true
        }
    }
    
    func position(of sample: Int) -> CGFloat? {
        let ratio = bounds.width / CGFloat(zoomSamples.count)
        let position = CGFloat(sample - zoomSamples.lowerBound) * ratio
        return (0...bounds.width).contains(position) ? position : nil
    }
    
    func sample(for position: CGFloat) -> Int {
        let ratio = CGFloat(zoomSamples.count) / bounds.width
        let sample = zoomSamples.lowerBound + Int(position * ratio)
        return min(max(0, sample), totalSamples)
    }
    
    @objc func startMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let startSample = sample(for: recognizer.location(in: self).x)
        
        guard let endSample = highlightedSamples?.upperBound, startSample < endSample else { return }
        highlightedSamples = startSample ..< endSample
        
        if recognizer.state == .ended {
            NotificationCenter.default.post(Notification(name: .startMarkerDragDidFinish))
        }
    }
    
    @objc func endMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let endSample = sample(for: recognizer.location(in: self).x)
        
        guard let startSample = highlightedSamples?.lowerBound, startSample < endSample else { return }
        highlightedSamples = startSample ..< endSample
        
        if recognizer.state == .ended {
            NotificationCenter.default.post(Notification(name: .endMarkerDragDidFinish))
        }
    }
    
}
