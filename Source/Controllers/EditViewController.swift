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
        if let startSample = waveformView.highlightedSamples?.lowerBound, let x = waveformView.position(of: startSample) {
            startPlayButtonHorizontalLayoutConstraint.constant = waveformView.position(of: startSample) ?? 0
            startMarkerHorizontalLayoutConstraint.constant = x
            startMarkerView.isHidden = false
        } else {
            startMarkerView.isHidden = true
        }
        
        if let endSample = waveformView.highlightedSamples?.upperBound, let x = waveformView.position(of: endSample) {
            endPlayButtonHorizontalLayoutConstraint.constant = waveformView.position(of: endSample) ?? waveformView.bounds.width
            endMarkerView.isHidden = false
            endMarkerHorizontalLayoutConstraint.constant = x
        } else {
            endMarkerView.isHidden = true
        }
    }
    
    @objc func startMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let startSample = waveformView.sample(for: recognizer.location(in: waveformView).x)
        
        guard let endSample = waveformView.highlightedSamples?.upperBound, startSample < endSample else { return }
        waveformView.highlightedSamples = startSample ..< endSample
        
        if recognizer.state == .ended {
            updateStartAndEndSamples()
            previewStart()
        }
    }
    
    @objc func endMarkerDragged(_ recognizer: UIPanGestureRecognizer) {
        let endSample = waveformView.sample(for: recognizer.location(in: waveformView).x)
        
        guard let startSample = waveformView.highlightedSamples?.lowerBound, startSample < endSample else { return }
        waveformView.highlightedSamples = startSample ..< endSample
        
        if recognizer.state == .ended {
            updateStartAndEndSamples()
            previewEnd()
        }
    }
    
    func updateStartAndEndSamples() {
        sting.startSample = Int64(waveformView.highlightedSamples?.lowerBound ?? 0)
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
    
    @IBAction func storeDefaults() {
        sting.storeDefaults()
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
