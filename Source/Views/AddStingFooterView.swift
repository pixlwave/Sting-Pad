import UIKit

class AddStingFooterView: UICollectionReusableView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.borderColor = tintColor.cgColor
        layer.borderWidth = 4
        layer.cornerRadius = 8
    }
    
}
