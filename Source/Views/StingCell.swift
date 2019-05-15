import UIKit

class StingCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    var isPlaying = false {
        didSet {
            backgroundColor = isPlaying ? .lightGray : .white
        }
    }
    
}
