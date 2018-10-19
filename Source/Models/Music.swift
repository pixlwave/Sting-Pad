import Foundation
import MediaPlayer

class Music {
    
    var allPlaylists: [MPMediaPlaylist] {
        return MPMediaQuery.playlists().collections as? [MPMediaPlaylist] ?? [MPMediaPlaylist]()
    }
    
    var playlist: MPMediaPlaylist?
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    init() {
        if let playlist = allPlaylists.first {
            musicPlayer.setQueue(with: playlist)
        }
        
        musicPlayer.beginGeneratingPlaybackNotifications()
        MPMediaLibrary.default().beginGeneratingLibraryChangeNotifications()
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
    
    func playItem(_ index: Int) {
        musicPlayer.nowPlayingItem = playlist?.items[index]
        play()
    }
    
    func nowPlayingItem() -> MPMediaItem? {
        return musicPlayer.nowPlayingItem
    }
    
    var nowPlayingItemIndex: Int? {
        guard let item = nowPlayingItem() else { return nil }
        return playlist?.items.firstIndex(of: item)
    }
    
    var isPlaying: Bool {
        if musicPlayer.playbackState == .playing {
            return true
        } else {
            return false
        }
    }
    
    func toggleShuffle() {
        if shuffleState {
            musicPlayer.shuffleMode = .off
        } else {
            musicPlayer.shuffleMode = .songs
        }
    }
    
    var shuffleState: Bool {
        if musicPlayer.shuffleMode == .off {
            return false
        } else {
            return true
        }
    }
    
    func refreshPlaylists() {
        // check if current playlist still exists, if not then set as nil
        // TODO: Test this out
        if let playlist = playlist, !allPlaylists.contains(playlist) {
            self.playlist = nil
        }
    }
    
    func getNamedPlaylist(_ name: String) -> MPMediaPlaylist? {
        var namedPlaylist: MPMediaPlaylist? = nil
    
        for playlist in allPlaylists {
            if playlist.name == name {
                namedPlaylist = playlist
            }
        }
        
        return namedPlaylist
    }
    
    func getAllPlaylists() -> [MPMediaPlaylist] {
        return MPMediaQuery.playlists().collections as! [MPMediaPlaylist]
    }
    
    func usePlaylist(_ index: Int) {
        if index < allPlaylists.count {
            playlist = allPlaylists[index]
            musicPlayer.setQueue(with: playlist!)
        }
    }
    
    var playlistIndex: Int? {
        if let playlist = playlist {
            return allPlaylists.index(of: playlist)
        }
        
        return nil
    }
}
