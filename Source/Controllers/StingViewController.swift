import UIKit

class StingViewController: UIViewController {
    
    // access the music
    let engine = Engine.shared
    
    enum Bound { case lower, upper }
    
    var stingIndex = 0
    var boundToEdit = Bound.lower
    var waveformView: FDWaveformView!
    
    @IBOutlet weak var stingNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var waveformLoadingImageView: UIImageView!
    @IBOutlet weak var loopSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        updateLabels()
        loopSwitch.isOn = engine.show.stings[stingIndex].loops
        
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
    
    func updateLabels() {
        let sting = engine.show.stings[stingIndex]
        
        if let name = sting.name {
            titleLabel.text = name
            subtitleLabel.text = sting.songTitle
        } else {
            titleLabel.text = sting.songTitle
            subtitleLabel.text = sting.songArtist
        }
    }
    
    @IBAction func rename() {
        let sting = engine.show.stings[stingIndex]
        
        let alertController = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in textField.text = sting.name }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            guard let name = alertController.textFields?.first?.text else { return }
            sting.name = name.isEmpty == false ? name : nil
            self.engine.show.updateChangeCount(.done)
            self.updateLabels()
            
            NotificationCenter.default.post(Notification(name: .stingsDidChange))
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func boundControlChanged(_ sender: UISegmentedControl) {
        boundToEdit = sender.selectedSegmentIndex == 0 ? .lower : .upper
    }
    
    
    @IBAction func startPreview() {
        engine.playSting(at: stingIndex)
    }

    @IBAction func stopPreview() {
        engine.stopSting()
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomSamples = Range(0...waveformView.totalSamples)
    }
    
    @IBAction func toggleLoop(_ sender: UISwitch) {
        engine.show.stings[stingIndex].loops = sender.isOn
        engine.show.updateChangeCount(.done)
    }
}


// MARK: FDWaveformViewDelegate
extension StingViewController: FDWaveformViewDelegate {
    
    func waveformViewDidLoad(_ waveformView: FDWaveformView) {
        // once the audio file has loaded (and totalSamples is known), set the highlighted samples
        waveformView.highlightedSamples = 0..<Int(engine.show.stings[stingIndex].startSample)
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformView.frame = waveformLoadingImageView.frame
        waveformLoadingImageView.isHidden = true
    }
    
    func waveformDidEndScrubbing(_ waveformView: FDWaveformView) {
        engine.show.stings[stingIndex].startSample = Int64(waveformView.highlightedSamples?.upperBound ?? 0)
        engine.show.updateChangeCount(.done)
    }
    
}
