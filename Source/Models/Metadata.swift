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
    
    var mediaQuery: MPMediaQuery {
        let query = MPMediaQuery.songs()
        #warning("TEST THIS ON DEVICE")
        #warning("What happens here if one of the values is nil?")
        query.addFilterPredicate(MPMediaPropertyPredicate(value: title, forProperty: MPMediaItemPropertyTitle))
        query.addFilterPredicate(MPMediaPropertyPredicate(value: artist, forProperty: MPMediaItemPropertyArtist))
        query.addFilterPredicate(MPMediaPropertyPredicate(value: albumTitle, forProperty: MPMediaItemPropertyAlbumTitle))
        query.addFilterPredicate(MPMediaPropertyPredicate(value: trackNumber, forProperty: MPMediaItemPropertyAlbumTrackNumber))
        query.addFilterPredicate(MPMediaPropertyPredicate(value: discNumber, forProperty: MPMediaItemPropertyDiscNumber))
        return query
    }
}
