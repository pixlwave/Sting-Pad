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
        let trackNumber = mediaItem.albumTrackNumber > 0 ? mediaItem.albumTrackNumber : nil
        let discNumber = mediaItem.discNumber > 0 ? mediaItem.discNumber : nil
        
        self.init(title: mediaItem.title, artist: mediaItem.artist, albumTitle: mediaItem.albumTitle, trackNumber: trackNumber, discNumber: discNumber)
    }
    
    init(url: URL) {
        self.init(title: url.songTitle(), artist: url.songArtist(), albumTitle: url.songAlbum(), trackNumber: nil, discNumber: nil)
    }
    
    var mediaQueryItems: [MPMediaItem]? {
        let query = MPMediaQuery.songs()
        
        if let title = title {
            query.addFilterPredicate(MPMediaPropertyPredicate(value: title, forProperty: MPMediaItemPropertyTitle))
        }
        
        if let artist = artist {
            query.addFilterPredicate(MPMediaPropertyPredicate(value: artist, forProperty: MPMediaItemPropertyArtist))
        }
        
        if let albumTitle = albumTitle {
            query.addFilterPredicate(MPMediaPropertyPredicate(value: albumTitle, forProperty: MPMediaItemPropertyAlbumTitle))
        }
        
        var items = query.items
        
        if let trackNumber = trackNumber, trackNumber > 0 {     // track number is 0 if missing
            // it's not possible to create a query with a track number predicate
            items?.removeAll(where: { $0.albumTrackNumber != trackNumber })
        }
        
        if let discNumber = discNumber, discNumber > 0 {        // disc number is 0 if missing
            // it's not possible to create a query with a disc number predicate
            items?.removeAll(where: { $0.discNumber != discNumber })
        }
        
        return items
    }
}
