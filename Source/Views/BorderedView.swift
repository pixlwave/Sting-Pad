import UIKit

class BorderedView: UIView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.borderColor = UIColor.secondaryLabel.cgColor
        layer.borderWidth = 4
        layer.cornerRadius = 8
    }
    
}
