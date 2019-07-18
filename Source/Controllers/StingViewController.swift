import UIKit

class StingViewController: UIViewController {
    
    // access the music
    let engine = Engine.shared
    let show = Show.shared
    
    enum Bound { case lower, upper }
    
    var sting: Sting!
    var waveformView: FDWaveformView!
    var playsPreviewsAutomatically = true
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var waveformLoadingView: UIView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var loopSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load track info
        updateLabels()
        if engine.playingSting != nil { previewButton.setTitle("Stop", for: .normal) }
        loopSwitch.isOn = sting.loops
        
        // set up the waveform view
        waveformView = FDWaveformView(frame: .zero)
        waveformView.delegate = self
        waveformView.doesAllowScrubbing = true
        waveformView.doesAllowScroll = true
        waveformView.doesAllowStretch = true
        waveformView.boundToScrub = .lower
        waveformView.wavesColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        waveformView.progressColor = .tintColor
        
        // render the waveform
        waveformView.audioURL = sting.url
        view.addSubview(waveformView)
        
        #warning("Add an override for automatic previews")
        if engine.playingSting != nil { playsPreviewsAutomatically = false }
    }
    
    override func viewDidLayoutSubviews() {
        waveformView.frame = waveformLoadingView.frame
    }
    
    func updateLabels() {
        navigationItem.title = sting.name ?? sting.songTitle
        titleLabel.text = sting.songTitle
        subtitleLabel.text = sting.songArtist
    }
    
    @IBAction func boundControlChanged(_ sender: UISegmentedControl) {
        waveformView.boundToScrub = sender.selectedSegmentIndex == 0 ? .lower : .upper
    }
    
    
    @IBAction func togglePreview() {
        if engine.playingSting == nil {
            previewButton.setTitle("Stop", for: .normal)
            engine.play(sting)
        } else {
            previewButton.setTitle("Preview", for: .normal)
            engine.stopSting()
        }
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomSamples = Range(0...waveformView.totalSamples)
    }
    
    @IBAction func toggleLoop(_ sender: UISwitch) {
        sting.loops = sender.isOn
        show.updateChangeCount(.done)
    }
    
    @IBAction func done() {
        dismiss(animated: true)
    }
}


// MARK: FDWaveformViewDelegate
extension StingViewController: FDWaveformViewDelegate {
    
    func waveformViewDidLoad(_ waveformView: FDWaveformView) {
        // once the audio file has loaded (and totalSamples is known), set the highlighted samples
        waveformView.highlightedSamples = Int(sting.startSample)..<Int(sting.endSample)
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformView.frame = waveformLoadingView.frame
        waveformLoadingView.isHidden = true
    }
    
    func waveformDidEndScrubbing(_ waveformView: FDWaveformView) {
        sting.startSample = Int64(waveformView.highlightedSamples?.lowerBound ?? 0)
        sting.endSample = Int64(waveformView.highlightedSamples?.upperBound ?? waveformView.totalSamples)
        show.updateChangeCount(.done)
        
        if playsPreviewsAutomatically {
            switch waveformView.boundToScrub {
            case .lower:
                engine.previewStart(of: sting)
            case .upper:
                engine.previewEnd(of: sting)
            }
        }
    }
    
}
