import Foundation
import MediaPlayer

class Music: NSObject {
    
    var allPlaylists: [MPMediaPlaylist] {
        return MPMediaQuery.playlistsQuery().collections as? [MPMediaPlaylist] ?? [MPMediaPlaylist]()
    }
    
    var playlist: MPMediaPlaylist?
    
    private var musicPlayer = MPMusicPlayerController.iPodMusicPlayer()
    
    override init() {
        
        super.init()
        
        if #available(iOS 8, *) {
            musicPlayer = MPMusicPlayerController.systemMusicPlayer()
        } else {
            musicPlayer = MPMusicPlayerController.iPodMusicPlayer()
        }
        
        if let playlist = allPlaylists.first {
            musicPlayer.setQueueWithItemCollection(playlist)
        }
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        MPMediaLibrary.defaultMediaLibrary().beginGeneratingLibraryChangeNotifications()
        
    }
    
    func play() {
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
    }
    
    func previous() {
        musicPlayer.skipToPreviousItem()
    }
    
    func next() {
        musicPlayer.skipToNextItem()
    }
    
    func playItem(index: Int) {
        musicPlayer.nowPlayingItem = playlist?.items[index]
        play()
    }
    
    func nowPlayingItem() -> MPMediaItem? {
        return musicPlayer.nowPlayingItem
    }
    
    var isPlaying: Bool {
        // if musicPlayer.playbackState == MPMusicPlaybackStatePlaying
        // workaround: http://stackoverflow.com/questions/18910207/ios7-mpmusicplayercontroller-states-incorrect
        
        if musicPlayer.currentPlaybackRate != 0 {
            return true
        } else {
            return false
        }
    }
    
    func toggleShuffle() {
        if shuffleState {
            musicPlayer.shuffleMode = .Off
        } else {
            musicPlayer.shuffleMode = .Songs
        }
    }
    
    var shuffleState: Bool {
        if musicPlayer.shuffleMode == .Off {
            return false
        } else {
            return true
        }
    }
    
    func refreshPlaylists() {
        // check if current playlist still exists, if not then set as nil
        // TODO: Test this out
        if let playlist = playlist where !allPlaylists.contains(playlist) {
            self.playlist = nil
        }
    }
    
    func getNamedPlaylist(name: String) -> MPMediaPlaylist? {
        var namedPlaylist: MPMediaPlaylist? = nil
    
        for playlist in allPlaylists {
            if (playlist.valueForProperty(MPMediaPlaylistPropertyName) as! String) == name {
                namedPlaylist = playlist
            }
        }
        
        return namedPlaylist
    }
    
    func getAllPlaylists() -> [MPMediaPlaylist] {
        return MPMediaQuery.playlistsQuery().collections as! [MPMediaPlaylist]
    }
    
    func usePlaylist(index: Int) {
        if index < allPlaylists.count {
            playlist = allPlaylists[index]
            musicPlayer.setQueueWithItemCollection(playlist!)
        }
    }
    
    var playlistIndex: Int? {
        if let playlist = playlist {
            return allPlaylists.indexOf(playlist)
        }
        
        return nil
    }
}
