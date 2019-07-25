import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loopIndicator: UIImageView!
    @IBOutlet weak var progressView: UIView!
    
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
            progressView.backgroundColor = isPlaying ? .lightGray : .clear
        }
    }
    
    var isCued = false {
        didSet {
            layer.borderWidth = isCued ? 3 : 0
            layer.borderColor = UIColor.borderColor.cgColor
        }
    }
    
}
