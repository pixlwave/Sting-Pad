import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var playbackIndicator: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loopIndicator: UIImageView!
    
    var color = Color.default {
        didSet {
            backgroundColor = color.value
        }
    }
    
    var loops = false {
        didSet {
            loopIndicator.isHidden = !loops
        }
    }
    
    var isPlaying = false {
        didSet {
            playbackIndicator.image = isPlaying ? UIImage(systemName: "play.circle.fill") : UIImage(systemName: "circle")
        }
    }
    
    var isCued = false {
        didSet {
            layer.borderColor = isCued ? UIColor.borderColor.cgColor : color.value.cgColor
        }
    }
    
}
