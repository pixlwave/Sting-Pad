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
        
        if let startSample = highlightedSamples?.lowerBound {
            startMarker.frame = CGRect(x: position(of: startSample) - startMarker.width / 2, y: 0, width: startMarker.width, height: frame.height)
        }
        
        if let endSample = highlightedSamples?.upperBound {
            endMarker.frame = CGRect(x: position(of: endSample) - endMarker.width / 2, y: 0, width: endMarker.width, height: frame.height)
        }
    }
    
    func position(of sample: Int) -> CGFloat {
        let ratio = bounds.width / CGFloat(zoomSamples.count)
        return CGFloat(sample - zoomSamples.lowerBound) * ratio
    }
    
    func sample(for position: CGFloat) -> Int {
        let ratio = CGFloat(zoomSamples.count) / bounds.width
        return zoomSamples.lowerBound + Int(position * ratio)
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
