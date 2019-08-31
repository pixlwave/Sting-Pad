import MediaPlayer

struct Metadata: Codable {
    let title: String?
    let artist: String?
    let albumTitle: String?
    let trackNumber: Int?
    let discNumber: Int?
}

extension Metadata {
    init(mediaItem: MPMediaItem) {
        self.init(title: mediaItem.title, artist: mediaItem.artist, albumTitle: mediaItem.albumTitle, trackNumber: mediaItem.albumTrackNumber, discNumber: mediaItem.discNumber)
    }
    
    init(url: URL) {
        self.init(title: url.songTitle(), artist: url.songArtist(), albumTitle: url.songAlbum(), trackNumber: nil, discNumber: nil)
    }
}
