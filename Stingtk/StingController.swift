import UIKit
import MediaPlayer

class StingController: UIViewController {
    
    // access the music
    let engine = Engine.sharedClient
    
    var stingIndex = 0
    var wave: FDWaveformView!   // could be computed?
    
    var observed: NSKeyValueObservation?
    
    @IBOutlet weak var stingNumberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet var waveLoadImageView: UIImageView! // FIXME: without weak, addSubview(waveLoadImageView) unwraps nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo"))
        
        // load track info
        stingNumberLabel.text = "Sting \(stingIndex + 1)"
        updateLabels()
        
        // get waveform view positions
        let waveFrame = waveLoadImageView.frame
        
        // not using whilst storing waveformView inside Sting object
        // @wave = FDWaveformView.alloc.initWithFrame(waveFrame)
        // @wave.doesAllowScrubbing = true
        // @wave.delegate = self
        // self.view.addSubview(@wave)
        // updateWaveURL()
        
        // temporary bodge to stop waveform being rendered each time it is presented
        // memory usage is probably excessive!
        wave = engine.sting[stingIndex].waveform
        if !engine.wavesLoaded[stingIndex] {
            wave.frame = waveFrame
        }
        
        wave.delegate = self
        view.addSubview(wave)
        
        observed = wave.observe(\.progressSamples, options: .new) { (waveformView, progressSamples) in
            if let newProgressSamples = progressSamples.newValue {
                let cue = Double(newProgressSamples) / Double(waveformView.totalSamples)
                self.engine.sting[self.stingIndex].setCue(cue)
                UserDefaults.standard.set(self.engine.sting[self.stingIndex].cuePoint, forKey: "Sting \(self.stingIndex) Cue Point")
            }
        }
        
        // temporary bodge to remove waveform loading image if the waveform isn't going to render
        if engine.wavesLoaded[stingIndex] {
            waveLoadImageView.removeFromSuperview()
        } else {
            // otherwise they will have loaded so save for next time
            engine.wavesLoaded[stingIndex] = true
        }
        
        // refresh playlists in case anything has changed
        engine.ipod.refreshPlaylists()
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
        wave.audioURL = engine.sting[stingIndex].url
        wave.progressSamples = Int(Double(wave.totalSamples) * engine.sting[stingIndex].getCue())
    }
    
    @IBAction func zoomWaveOut() {
        wave.zoomStartSamples = 0
        wave.zoomEndSamples = wave.totalSamples
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
        waveLoadImageView.removeFromSuperview()
    }
}

// MARK: MPMediaPickerControllerDelegate
extension StingController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // load media item into the currently loading sting player and update labels
        engine.sting[stingIndex].loadSting(mediaItemCollection.items[0])
        updateLabels()
        
        // add wave loading image whilst waveform generates
        view.addSubview(waveLoadImageView)
        
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
