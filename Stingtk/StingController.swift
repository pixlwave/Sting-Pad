import UIKit
import MediaPlayer

class StingController: UIViewController {
    
    // access the music
    let engine = Engine.sharedClient
    
    var stingIndex = 0
     var wave: FDWaveformView!   // could be computed?
    
    private var kvoContext = 0
    
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
        
        wave.addObserver(self, forKeyPath: "progressSamples", options: .New, context: &kvoContext)
        
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
    
    func dismiss() {
        // display updates before dismissing
        (presentingViewController as? StkController)?.updateStingTitles()
        wave.removeObserver(self, forKeyPath: "progressSamples")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loadTrack() {
        // present music picker to load a track from ipod
        let mediaPicker = MPMediaPickerController(mediaTypes: .Music)
        mediaPicker.delegate = self
        mediaPicker.showsCloudItems = false  // hides iTunes in the Cloud items, which crash the app if picked
        mediaPicker.allowsPickingMultipleItems = false
        presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    func updateLabels() {
        // get all the relevant track info from the engine
        titleLabel.text = engine.sting[stingIndex].title
        artistLabel.text = engine.sting[stingIndex].artist
    }
    
    func updateWaveURL() {
        wave.audioURL = engine.sting[stingIndex].url
        wave.progressSamples = UInt(Double(wave.totalSamples) * engine.sting[stingIndex].getCue())
    }
    
    func zoomWaveOut() {
        wave.zoomStartSamples = 0
        wave.zoomEndSamples = wave.totalSamples
    }
    
    func startPreview() {
        engine.playSting(stingIndex)
    }

    func stopPreview() {
        engine.stopSting()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kvoContext {
            let cue = Double(change?[NSKeyValueChangeNewKey] as! NSNumber) / Double(wave.totalSamples)
            engine.sting[stingIndex].setCue(cue)
            Defaults["Sting \(stingIndex) Cue Point"] = engine.sting[stingIndex].cuePoint
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
}

// MARK: FDWaveformViewDelegate
extension StingController: FDWaveformViewDelegate {
    func waveformViewDidRender(waveform: FDWaveformView) {
        waveLoadImageView.removeFromSuperview()
    }
}

// MARK: MPMediaPickerControllerDelegate
extension StingController: MPMediaPickerControllerDelegate {
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // load media item into the currently loading sting player and update labels
        engine.sting[stingIndex].loadSting(mediaItemCollection.items[0])
        updateLabels()
        
        // add wave loading image whilst waveform generates
        view.addSubview(waveLoadImageView)
        
        // generate new waveform
        updateWaveURL()
        
        save(engine.sting[stingIndex])
        
        // dismiss media picker
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        // dismiss media picker
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func save(sting: Sting) {
        Defaults["Sting \(stingIndex) URL"] = sting.url
        Defaults["Sting \(stingIndex) Cue Point"] = sting.cuePoint
        Defaults["Sting \(stingIndex) Title"] = sting.title
        Defaults["Sting \(stingIndex) Artist"] = sting.artist
    }
}
