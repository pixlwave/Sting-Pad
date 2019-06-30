import Foundation
import AVFoundation
import MediaPlayer

extension URL {
    func songTitle() -> String? {
        if scheme == "ipod-library" {
            return mediaItem()?.title
        } else if isFileURL {
            if let metadata = metadata() {
                let title = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierTitle).first
                return title?.stringValue
            }
        }
        
        return nil
    }
    
    func songArtist() -> String? {
        if scheme == "ipod-library" {
            return mediaItem()?.artist
        } else if isFileURL {
            if let metadata = metadata() {
                let artist = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .commonIdentifierArtist).first
                return artist?.stringValue
            }
        }
        
        return nil
    }
    
    func mediaItem() -> MPMediaItem? {
        guard
            let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let idQuery = components.queryItems?.filter({ $0.name == "id" }).first,
            let persistentID = idQuery.value
            else {
                return nil
        }
        
        let mediaQuery = MPMediaQuery(filterPredicates: [MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyPersistentID)])
        
        return mediaQuery.items?.first
    }
    
    func metadata() -> [AVMetadataItem]? {
        let asset = AVAsset(url: self)
        return asset.metadata
    }
}


extension AVAudioPCMBuffer {
    convenience init?(for audioFile: AVAudioFile) {
        self.init(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
    }
}


extension Notification.Name {
    static let stingsDidChange = Notification.Name("Stings Did Change")
}


extension CGColor {
    static let cuedStingBackgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
}


extension TimeInterval {
    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.includesTimeRemainingPhrase = true
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func formatted() -> String? {
        return TimeInterval.formatter.string(from: self)
    }
}