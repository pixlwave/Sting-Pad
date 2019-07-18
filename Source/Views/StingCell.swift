import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    var color = Color.default {
        didSet {
            colorView.backgroundColor = color.value
        }
    }
    
    var isPlaying = false {
        didSet {
            backgroundColor = isPlaying ? .lightGray : .backgroundColor
        }
    }
    
    var isCued = false {
        didSet {
            layer.borderWidth = isCued ? 3 : 0
            layer.borderColor = UIColor.borderColor.cgColor
        }
    }
    
}
