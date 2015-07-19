import Foundation

class Engine {
    static let sharedClient = Engine()
    
    var sting = [Sting]()
    var ipod = Music()
    
    var wavesLoaded = [false, false, false, false, false]
    private var playingSting = 0
    
    init() {
        for i in 0..<5 {
            let url = Defaults["Sting \(i) URL"].url ?? Sting.defaultURL
            let title = Defaults["Sting \(i) Title"].string ?? "Chime"
            let artist = Defaults["Sting \(i) Artist"].string ?? "Default Sting"
            let cuePoint = Defaults["Sting \(i) Cue Point"].double ?? 0
            sting.append(Sting(url: url, title: title, artist: artist, cuePoint: cuePoint))
        }
    
        let playlistIndex = Defaults["Playlist Index"].int ?? 0
        ipod.usePlaylist(playlistIndex)
    }
    
    func playSting(selectedSting: Int) {
        ipod.pause()
        if selectedSting != playingSting { sting[playingSting].stop() }
        sting[selectedSting].play()
        playingSting = selectedSting
    }
    
    func stopSting() {
        sting[playingSting].stop()
    }
    
    func playiPod() {
        sting[playingSting].stop()
        ipod.play()
    }
    
    func playiPodItem(index: Int) {
        sting[playingSting].stop()
        ipod.playItem(index)
    }
    
    func pauseiPod() {
        ipod.pause()
    }
    
    func setStingDelegates(delegate: StingDelegate) {
        for s in sting {
            s.delegate = delegate
        }
    }
    
}
