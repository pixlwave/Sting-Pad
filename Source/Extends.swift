import Foundation
import AVFoundation
import MediaPlayer

extension URL {
    var isMediaItem: Bool { scheme == "ipod-library" }
    var isFileInsideInbox: Bool {
        guard isFileURL, let inboxURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Inbox") else {
            return false
        }
        
        let directoryURL = resolvingSymlinksInPath().deletingLastPathComponent()  // resolve symlinks to match /private/var with /var
        return directoryURL == inboxURL
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
    
    func metadata() async -> [AVMetadataItem]? {
        let asset = AVURLAsset(url: self)
        return try? await asset.load(.metadata)
    }
}


extension [AVMetadataItem] {
    func title() async -> String? {
        let data = AVMetadataItem.metadataItems(from: self, filteredByIdentifier: .commonIdentifierTitle).first
        return try? await data?.load(.stringValue)
    }
    func artist() async -> String? {
        let data = AVMetadataItem.metadataItems(from: self, filteredByIdentifier: .commonIdentifierArtist).first
        return try? await data?.load(.stringValue)
    }
    func albumName() async -> String? {
        let data = AVMetadataItem.metadataItems(from: self, filteredByIdentifier: .commonIdentifierAlbumName).first
        return try? await data?.load(.stringValue)
    }
}


extension AVAudioPCMBuffer {
    convenience init?(for audioFile: AVAudioFile) {
        self.init(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
    }
}


extension Notification.Name {
    static let addStingFromLibrary = Notification.Name("Add Sting From Library")
    static let addStingFromFiles = Notification.Name("Add Sting From Files")
    static let didAppendSting = Notification.Name("Did Append Sting")
    static let stingsDidChange = Notification.Name("Stings Did Change")
    static let unavailableStingsDidChange = Notification.Name("Unavailable Stings Did Change")
    static let waveformViewDidLayoutSubviews = Notification.Name("Waveform View Did Layout Subviews")
    static let didFinishEditing = Notification.Name("Did Finish Editing")
}


extension TimeInterval {
    static let lengthFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static let remainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.includesTimeRemainingPhrase = true
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func formattedAsLength() -> String? {
        return TimeInterval.lengthFormatter.string(from: self)
    }
    
    func formattedAsRemaining() -> String? {
        return TimeInterval.remainingFormatter.string(from: self)
    }
}

extension UIColor {
    static let backgroundColor = UIColor(named: "Background Color")!
    static let borderColor = UIColor(named: "Border Color")!
    static let tintColor = UIColor(named: "Tint Color")!
}


extension UserDefaults {
    static let presets = UserDefaults(suiteName: "uk.pixlwave.StingPad.Presets")!
}


extension UIProgressView {
    func reset() {
        progress = 0
        layoutIfNeeded()
    }
}


extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
