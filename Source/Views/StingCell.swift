import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var playbackIndicator: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loopIndicator: UIImageView!
    
    var color = Color.default {
        didSet {
            backgroundColor = color.value
            playbackIndicator.tintColor = color.value
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
            updateBorder()
        }
    }
    
    var isCued = false {
        didSet {
            updateBorder()
        }
    }
    
    func updateBorder() {
        if isPlaying {
            layer.borderColor = color.value.cgColor
        } else if isCued {
            layer.borderColor = UIColor.borderColor.cgColor
        } else {
            layer.borderColor = UIColor.clear.cgColor
        }
    }
    
}
