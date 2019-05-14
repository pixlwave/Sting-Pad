import UIKit
import MediaPlayer

class StingViewController: UIViewController {
    
    // access the music
    let engine = Engine.shared
    
    var stingIndex = 0
    var waveformView: FDWaveformView!
    
    @IBOutlet weak var stingNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet var waveformLoadingImageView: UIImageView!; #warning("without weak, addSubview(waveformLoadingImageView) unwraps nil")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "logo"))
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        updateLabels()
        
        waveformView = FDWaveformView(frame: waveformLoadingImageView.frame)
        waveformView.doesAllowScrubbing = true
        waveformView.doesAllowScrubbing = true
        waveformView.doesAllowScroll = false
        waveformView.doesAllowStretch = false
        waveformView.wavesColor = UIColor(red: 0.25, green: 0.25, blue: 1.0, alpha: 1.0)
        waveformView.progressColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        updateWaveURL()
        
        waveformView.delegate = self
        view.addSubview(waveformView)
    }
    
    @IBAction func done() {
        // display updates before dismissing
        (presentingViewController as? MainViewController)?.updateSting(at: IndexPath(item: stingIndex, section: 0))
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loadTrack() {
        // present music picker to load a track from ipod
        let mediaPicker = MPMediaPickerController(mediaTypes: .music)
        mediaPicker.delegate = self
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.allowsPickingMultipleItems = false
        present(mediaPicker, animated: true, completion: nil)
    }
    
    func updateLabels() {
        // get all the relevant track info from the engine
        titleLabel.text = engine.stings[stingIndex].title
        artistLabel.text = engine.stings[stingIndex].artist
    }
    
    func updateWaveURL() {
        waveformView.audioURL = engine.stings[stingIndex].url
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
        waveformView.highlightedSamples = 0..<Int(Double(waveformView.totalSamples) * engine.stings[stingIndex].getCue())
    }
    
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformLoadingImageView.isHidden = true
    }
    
    func waveformDidEndScrubbing(_ waveformView: FDWaveformView) {
        let cue = Double(waveformView.highlightedSamples?.endIndex ?? 0) / Double(waveformView.totalSamples)
        engine.stings[stingIndex].setCue(cue)
        UserDefaults.standard.set(engine.stings[stingIndex].cuePoint, forKey: "StingCuePoint\(stingIndex)")
    }
    
}


// MARK: MPMediaPickerControllerDelegate
extension StingViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // load media item into the currently loading sting player and update labels
        engine.stings[stingIndex].loadSting(mediaItemCollection.items[0])
        updateLabels()
        
        // add wave loading image whilst waveform generates
        waveformLoadingImageView.isHidden = false
        
        // generate new waveform
        updateWaveURL()
        
        save(engine.stings[stingIndex])
        
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
    func save(_ sting: Sting) {
        UserDefaults.standard.set(sting.url, forKey: "StingURL\(stingIndex)")
        UserDefaults.standard.set(sting.cuePoint, forKey: "StingCuePoint\(stingIndex)")
        UserDefaults.standard.set(sting.title, forKey: "StingTitle\(stingIndex)")
        UserDefaults.standard.set(sting.artist, forKey: "StingArtist\(stingIndex)")
    }
    
}
