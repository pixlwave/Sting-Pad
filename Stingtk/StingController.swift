import UIKit
import MediaPlayer

class StingController: UIViewController {
    
    // access the music
    let engine = Engine.sharedClient
    
    var stingIndex = 0
    var waveformView: FDWaveformView!   // could be computed?
    
    @IBOutlet weak var stingNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet var waveformLoadingImageView: UIImageView! // FIXME: without weak, addSubview(waveformLoadingImageView) unwraps nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo"))
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        updateLabels()
        
        // refresh playlists in case anything has changed
        engine.ipod.refreshPlaylists()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // get waveform view positions
        let waveformFrame = waveformLoadingImageView.frame
        
        // not using whilst storing waveformView inside Sting object
        // @waveformView = FDWaveformView.alloc.initWithFrame(waveFrame)
        // @waveformView.doesAllowScrubbing = true
        // @waveformView.delegate = self
        // self.view.addSubview(@waveformView)
        // updateWaveURL()
        
        // temporary bodge to stop waveform being rendered each time it is presented
        // memory usage is probably excessive!
        waveformView = engine.sting[stingIndex].waveform
        if !engine.wavesLoaded[stingIndex] {
            waveformView.frame = waveformFrame
        }
        
        waveformView.delegate = self
        view.addSubview(waveformView)
        
        // temporary bodge to remove waveform loading image if the waveform isn't going to render
        if engine.wavesLoaded[stingIndex] {
            waveformLoadingImageView.removeFromSuperview()
        } else {
            // otherwise they will have loaded so save for next time
            engine.wavesLoaded[stingIndex] = true
        }
    }
    
    @IBAction func done() {
        // display updates before dismissing
        (presentingViewController as? StkController)?.updateStingTitles()
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
        titleLabel.text = engine.sting[stingIndex].title
        artistLabel.text = engine.sting[stingIndex].artist
    }
    
    func updateWaveURL() {
        waveformView.audioURL = engine.sting[stingIndex].url
        waveformView.progressSamples = Int(Double(waveformView.totalSamples) * engine.sting[stingIndex].getCue())
    }
    
    @IBAction func zoomWaveOut() {
        waveformView.zoomStartSamples = 0
        waveformView.zoomEndSamples = waveformView.totalSamples
    }
    
    @IBAction func startPreview() {
        engine.playSting(stingIndex)
    }

    @IBAction func stopPreview() {
        engine.stopSting()
    }
    
}

// MARK: FDWaveformViewDelegate
extension StingController: FDWaveformViewDelegate {
    func waveformViewDidRender(_ waveform: FDWaveformView) {
        waveformLoadingImageView.removeFromSuperview()
    }
    
    func waveformDidEndScrubbing(_ waveformView: FDWaveformView) {
        let cue = Double(waveformView.progressSamples) / Double(waveformView.totalSamples)
        engine.sting[stingIndex].setCue(cue)
        UserDefaults.standard.set(engine.sting[stingIndex].cuePoint, forKey: "Sting \(stingIndex) Cue Point")
    }
}

// MARK: MPMediaPickerControllerDelegate
extension StingController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // load media item into the currently loading sting player and update labels
        engine.sting[stingIndex].loadSting(mediaItemCollection.items[0])
        updateLabels()
        
        // add wave loading image whilst waveform generates
        view.addSubview(waveformLoadingImageView)
        
        // generate new waveform
        updateWaveURL()
        
        save(engine.sting[stingIndex])
        
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        // dismiss media picker
        dismiss(animated: true, completion: nil)
    }
    
    func save(_ sting: Sting) {
        UserDefaults.standard.set(sting.url, forKey: "Sting \(stingIndex) URL")
        UserDefaults.standard.set(sting.cuePoint, forKey: "Sting \(stingIndex) Cue Point")
        UserDefaults.standard.set(sting.title, forKey: "Sting \(stingIndex) Title")
        UserDefaults.standard.set(sting.artist, forKey: "Sting \(stingIndex) Artist")
    }
}
