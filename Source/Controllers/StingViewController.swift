import UIKit

class StingViewController: UIViewController {
    
    // access the music
    let engine = Engine.shared
    
    var stingIndex = 0
    var waveformView: FDWaveformView!
    
    @IBOutlet weak var stingNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var waveformLoadingImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        titleLabel.text = engine.show.stings[stingIndex].title
        artistLabel.text = engine.show.stings[stingIndex].artist
        
        // set up the waveform view
        waveformView = FDWaveformView(frame: .zero)
        waveformView.delegate = self
        waveformView.doesAllowScrubbing = true
        waveformView.doesAllowScroll = true
        waveformView.doesAllowStretch = true
        waveformView.wavesColor = UIColor(red: 0.25, green: 0.25, blue: 1.0, alpha: 1.0)
        waveformView.progressColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        
        // render the waveform
        waveformView.audioURL = engine.show.stings[stingIndex].url
        view.addSubview(waveformView)
    }
    
    override func viewWillLayoutSubviews() {
        waveformView.frame = waveformLoadingImageView.frame
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomSamples = Range(0...waveformView.totalSamples)
    }
    
    @IBAction func startPreview() {
        engine.playSting(stingIndex)
    }

    @IBAction func stopPreview() {
        engine.stopSting()
    }
    
}


// MARK: FDWaveformViewDelegate
extension StingViewController: FDWaveformViewDelegate {
    
    func waveformViewDidLoad(_ waveformView: FDWaveformView) {
        // once the audio file has loaded (and totalSamples is known), set the highlighted samples
        waveformView.highlightedSamples = 0..<Int(Double(waveformView.totalSamples) * engine.show.stings[stingIndex].normalisedCuePoint)
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformView.frame = waveformLoadingImageView.frame
        waveformLoadingImageView.isHidden = true
    }
    
    func waveformDidEndScrubbing(_ waveformView: FDWaveformView) {
        engine.show.stings[stingIndex].normalisedCuePoint = Double(waveformView.highlightedSamples?.endIndex ?? 0) / Double(waveformView.totalSamples)
        engine.show.updateChangeCount(.done)
    }
    
}
