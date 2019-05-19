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
    @IBOutlet weak var stingPickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        waveformView = FDWaveformView(frame: waveformLoadingImageView.frame)
        waveformView.delegate = self
        waveformView.doesAllowScrubbing = true
        waveformView.doesAllowScroll = true
        waveformView.doesAllowStretch = true
        waveformView.wavesColor = UIColor(red: 0.25, green: 0.25, blue: 1.0, alpha: 1.0)
        waveformView.progressColor = UIColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
        
        loadSting(at: stingIndex)
        view.addSubview(waveformView)
    }
    
    func loadSting(at index: Int) {
        stingIndex = index
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        updateLabels()
        updateWaveURL()
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
        
        // update the sting picker
        stingPickerView.reloadComponent(0)
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
    
    @IBAction func addSting() {
        engine.addSting()
        stingPickerView.reloadComponent(0)
        stingPickerView.selectRow(engine.stings.count - 1, inComponent: 0, animated: true)
        loadSting(at: stingPickerView.selectedRow(inComponent: 0))
    }
    
    @IBAction func deleteSting() {
        
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
        engine.save(); #warning("This is probably bad for performance!")
    }
    
}


// MARK: MPMediaPickerControllerDelegate
extension StingViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // load media item into the currently loading sting player and update labels
        if let newSting = Sting(mediaItem: mediaItemCollection.items[0]) {
            engine.stings[stingIndex] = newSting
            updateLabels()
            
            // add wave loading image whilst waveform generates
            waveformLoadingImageView.isHidden = false
            
            // generate new waveform
            updateWaveURL()
            
            engine.save()
        }
        
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
}


// MARK: UIPickerViewDataSource
extension StingViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return engine.stings.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return engine.stings[row].title
    }
}


// MARK: UIPickerViewDelegate
extension StingViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        loadSting(at: row)
    }
}
