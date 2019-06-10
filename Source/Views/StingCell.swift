import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var isPlaying = false {
        didSet {
            backgroundColor = isPlaying ? .lightGray : UIColor(named: "Background Color")
        }
    }
    
    var isCued = false {
        didSet {
            layer.borderWidth = isCued ? 3 : 0
            layer.borderColor = .cuedStingBackgroundColor
        }
    }
    
}
