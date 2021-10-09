import UIKit
import AVFoundation

class WaveformViewController: UIViewController {
    
    var coordinator: Waveform.Coordinator?
    
    // access the music
    let engine = Engine.shared
    var show: Show!
    
    var sting: Sting!
    var hasSecurityScopedAccess = false
    var previewLength: TimeInterval = 2 {
        didSet {
            startPlayButton.isEnabled = previewLength > 0
            endPlayButton.isEnabled = previewLength > 0
        }
    }
    
    @IBOutlet weak var waveformView: WaveformView!
    @IBOutlet weak var waveformLoadingView: UIView!
    @IBOutlet weak var startPlayButton: UIButton!
    @IBOutlet weak var startPlayButtonHorizontalLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var startMarkerView: WaveformMarkerView!
    @IBOutlet weak var startMarkerHorizontalLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var endPlayButton: UIButton!
    @IBOutlet weak var endPlayButtonHorizontalLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var endMarkerView: WaveformMarkerView!
    @IBOutlet weak var endMarkerHorizontalLayoutConstraint: NSLayoutConstraint!
    
    override var undoManager: UndoManager? { show.undoManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the waveform view
        waveformView.delegate = self
        waveformView.doesAllowScrubbing = false
        waveformView.doesAllowScroll = true
        waveformView.doesAllowStretch = true
        waveformView.wavesColor = UIColor(white: 0.4, alpha: 1.0)
        waveformView.progressColor = UIColor.tintColor.withAlphaComponent(0.5)
        
        // safely access the url
        hasSecurityScopedAccess = sting.url.startAccessingSecurityScopedResource()
        
        // render the waveform
        waveformView.audioURL = sting.url
        
        NotificationCenter.default.addObserver(self, selector: #selector(layoutWaveformOverlayViews), name: .waveformViewDidLayoutSubviews, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateHighlightedSamples), name: .NSUndoManagerDidUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateHighlightedSamples), name: .NSUndoManagerDidRedoChange, object: nil)
        
        startMarkerView.dragRecogniser.addTarget(self, action: #selector(startMarkerDragged(_:)))
        endMarkerView.dragRecogniser.addTarget(self, action: #selector(endMarkerDragged(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // the sting's cell will only reload when previewed, so force a reload in case it wasn't previewed.
        NotificationCenter.default.post(name: .didFinishEditing, object: sting)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // remove access to the url when finished
        if hasSecurityScopedAccess {
            #warning("Is this holding onto access for too long?")
            sting.url.stopAccessingSecurityScopedResource()
        }
    }
    
    @objc func updateHighlightedSamples() {
        waveformView.highlightedSamples = Int(sting.startSample) ..< Int(sting.endSample)
    }
    
    @objc func layoutWaveformOverlayViews() {
        if let startPosition = waveformView.startPosition {
            startPlayButtonHorizontalLayoutConstraint.constant = startPosition
            startMarkerHorizontalLayoutConstraint.constant = startPosition
            waveformView.startMarkerLine.frame = CGRect(x: startPosition - 1, y: 0, width: 2, height: waveformView.bounds.height)
            startMarkerView.isHidden = false
            waveformView.startMarkerLine.isHidden = false
        } else {
            startPlayButtonHorizontalLayoutConstraint.constant = 0
            startMarkerView.isHidden = true
            waveformView.startMarkerLine.isHidden = true
        }
        
        if let endPosition = waveformView.endPosition {
            endPlayButtonHorizontalLayoutConstraint.constant = endPosition
            endMarkerHorizontalLayoutConstraint.constant = endPosition
            waveformView.endMarkerLine.frame = CGRect(x: endPosition - 1, y: 0, width: 2, height: waveformView.bounds.height)
            endMarkerView.isHidden = false
            waveformView.endMarkerLine.isHidden = false
        } else {
            endPlayButtonHorizontalLayoutConstraint.constant = waveformView.bounds.width
            endMarkerView.isHidden = true
            waveformView.endMarkerLine.isHidden = true
        }
    }
    
    @objc func startMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let startSample = waveformView.sample(for: recognizer.location(in: waveformView).x)
        
        if let endSample = waveformView.highlightedSamples?.upperBound, startSample < endSample {
            waveformView.highlightedSamples = startSample ..< endSample
        }
        
        if recognizer.state == .ended {
            // get the sample from the waveform in case the ended with an invalid location
            setStartSample(to: AVAudioFramePosition(waveformView.highlightedSamples?.lowerBound ?? 0))
            previewStart()
        }
    }
    
    @objc func endMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let endSample = waveformView.sample(for: recognizer.location(in: waveformView).x)
        
        if let startSample = waveformView.highlightedSamples?.lowerBound, startSample < endSample {
            waveformView.highlightedSamples = startSample ..< endSample
        }
        
        if recognizer.state == .ended {
            // get the sample from the waveform in case the ended with an invalid location
            setEndSample(to: AVAudioFramePosition(waveformView.highlightedSamples?.upperBound ?? waveformView.totalSamples))
            previewEnd()
        }
    }
    
    func setStartSample(to sample: AVAudioFramePosition) {
        guard sample != sting.startSample else { return }
        
        let oldSample = sting.startSample
        sting.startSample = sample
        undoManager?.registerUndo(withTarget: self) {
            $0.setStartSample(to: oldSample)
        }
    }
    
    func setEndSample(to sample: AVAudioFramePosition) {
        guard sample != sting.endSample else { return }
        
        let oldSample = sting.endSample
        sting.endSample = sample
        undoManager?.registerUndo(withTarget: self) {
            $0.setEndSample(to: oldSample)
        }
    }
    
    @IBAction func previewStart() {
        if previewLength < 10 {
            engine.previewStart(of: sting, for: previewLength)
        } else {
            engine.play(sting)
        }
    }
    
    @IBAction func previewEnd() {
        if previewLength < 10 {
            engine.previewEnd(of: sting, for: previewLength)
        } else {
            engine.play(sting)
        }
    }
    
    @IBAction func stop() {
        engine.stopSting()
        
        // re-enable previews now that the previous sting has been stopped
        if previewLength == 0 {
            previewLength = 2
            coordinator?.setPreviewLength(2)
        }
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomSamples = Range(0...waveformView.totalSamples)
    }
}


// MARK: FDWaveformViewDelegate
extension WaveformViewController: FDWaveformViewDelegate {
    
    func waveformViewDidLoad(_ waveformView: FDWaveformView) {
        // once the audio file has loaded (and totalSamples is known), set the highlighted samples
        waveformView.highlightedSamples = Int(sting.startSample)..<Int(sting.endSample)
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformLoadingView.isHidden = true
    }
    
}
