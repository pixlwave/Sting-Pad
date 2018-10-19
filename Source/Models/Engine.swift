import Foundation

class Engine {
    static let shared = Engine()
    
    var sting = [Sting]()
    var ipod = Music()
    
    private var playingSting = 0
    
    init() {
        for i in 0..<5 {
            let url = UserDefaults.standard.url(forKey: "StingURL\(i)") ?? Sting.defaultURL
            let title = UserDefaults.standard.string(forKey: "StingTitle\(i)") ?? "Chime"
            let artist = UserDefaults.standard.string(forKey: "StingArtist\(i)") ?? "Default Sting"
            let cuePoint = UserDefaults.standard.double(forKey: "StingCuePoint\(i)")
            sting.append(Sting(url: url, title: title, artist: artist, cuePoint: cuePoint))
        }
    
        let playlistIndex = UserDefaults.standard.integer(forKey: "PlaylistIndex") 
        ipod.usePlaylist(playlistIndex)
    }
    
    func playSting(_ selectedSting: Int) {
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
    
    func playiPodItem(_ index: Int) {
        sting[playingSting].stop()
        ipod.playItem(index)
    }
    
    func pauseiPod() {
        ipod.pause()
    }
    
    func setStingDelegates(_ delegate: StingDelegate) {
        for s in sting {
            s.delegate = delegate
        }
    }
    
}
