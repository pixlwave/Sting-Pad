import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var playbackIndicator: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var loopIndicator: UIImageView!
    
    var color = Color.default {
        didSet {
            backgroundColor = color.value
            layer.borderColor = color.value.cgColor
        }
    }
    
    var loops = false {
        didSet {
            loopIndicator.isHidden = !loops
        }
    }
    
    var isPlaying = false {
        didSet {
            updatePlaybackIndicator()
        }
    }
    
    var isCued = false {
        didSet {
            updatePlaybackIndicator()
        }
    }
    
    var isMissing = false {
        didSet {
            updatePlaybackIndicator()
        }
    }
    
    func updatePlaybackIndicator() {
        if isMissing {
            playbackIndicator.image = UIImage(systemName: "exclamationmark.octagon")
            playbackIndicator.tintColor = .white
        } else if isPlaying {
            playbackIndicator.image = UIImage(systemName: "play.circle.fill")
            playbackIndicator.tintColor = .white
        } else if isCued{
            playbackIndicator.image = UIImage(systemName: "pause.circle")
            playbackIndicator.tintColor = .white
        } else {
            playbackIndicator.image = UIImage(systemName: "circle")
            playbackIndicator.tintColor = .backgroundColor
        }
    }
    
}
