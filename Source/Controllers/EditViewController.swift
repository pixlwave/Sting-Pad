import UIKit

class EditViewController: UIViewController {
    
    // access the music
    let engine = Engine.shared
    var show: Show?
    
    var sting: Sting!
    var hasSecurityScopedAccess = false
    var previewLength: [TimeInterval] = [0, 1, 2, 5, 10]
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
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
    @IBOutlet weak var loopSwitch: UISwitch!
    @IBOutlet weak var previewLengthControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load track info
        updateLabels()
        loopSwitch.isOn = sting.loops
        
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
        
        startMarkerView.dragRecogniser.addTarget(self, action: #selector(startMarkerDragged(_:)))
        endMarkerView.dragRecogniser.addTarget(self, action: #selector(endMarkerDragged(_:)))
        
        if engine.playingSting != nil {
            previewLengthControl.selectedSegmentIndex = 0
            previewLengthDidChange()
        }
        
        show?.undoManager.removeAllActions()
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
        
        show?.undoManager.removeAllActions()
    }
    
    func updateLabels() {
        navigationItem.title = sting.name ?? sting.songTitle
        titleLabel.text = sting.songTitle
        subtitleLabel.text = sting.songArtist
    }
    
    @IBAction func previewLengthDidChange() {
        startPlayButton.isEnabled = previewLengthControl.selectedSegmentIndex > 0
        endPlayButton.isEnabled = previewLengthControl.selectedSegmentIndex > 0
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
            updateStartSample()
            previewStart()
        }
    }
    
    @objc func endMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let endSample = waveformView.sample(for: recognizer.location(in: waveformView).x)
        
        if let startSample = waveformView.highlightedSamples?.lowerBound, startSample < endSample {
            waveformView.highlightedSamples = startSample ..< endSample
        }
        
        if recognizer.state == .ended {
            updateEndSample()
            previewEnd()
        }
    }
    
    func updateStartSample() {
        sting.startSample = Int64(waveformView.highlightedSamples?.lowerBound ?? 0)
        show?.updateChangeCount(.done)
    }
    
    func updateEndSample() {
        sting.endSample = Int64(waveformView.highlightedSamples?.upperBound ?? waveformView.totalSamples)
        show?.updateChangeCount(.done)
    }
    
    @IBAction func previewStart() {
        let length = previewLength[previewLengthControl.selectedSegmentIndex]
        if length < 10 {
            engine.previewStart(of: sting, for: length)
        } else {
            engine.play(sting)
        }
    }
    
    @IBAction func previewEnd() {
        let length = previewLength[previewLengthControl.selectedSegmentIndex]
        if length < 10 {
            engine.previewEnd(of: sting, for: length)
        } else {
            engine.play(sting)
        }
    }
    
    @IBAction func stop() {
        engine.stopSting()
        
        // re-enable previews now that the previous sting has been stopped
        if previewLengthControl.selectedSegmentIndex == 0 {
            previewLengthControl.selectedSegmentIndex = 2
            previewLengthDidChange()
        }
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomSamples = Range(0...waveformView.totalSamples)
    }
    
    @IBAction func toggleLoop(_ sender: UISwitch) {
        sting.loops = sender.isOn
        show?.updateChangeCount(.done)
    }
    
    @IBAction func saveAsPreset() {
        sting.setPreset()
    }
    
    @IBAction func done() {
        dismiss(animated: true)
    }
}


// MARK: FDWaveformViewDelegate
extension EditViewController: FDWaveformViewDelegate {
    
    func waveformViewDidLoad(_ waveformView: FDWaveformView) {
        // once the audio file has loaded (and totalSamples is known), set the highlighted samples
        waveformView.highlightedSamples = Int(sting.startSample)..<Int(sting.endSample)
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformLoadingView.isHidden = true
    }
    
}
