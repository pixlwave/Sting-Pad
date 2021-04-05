import UIKit

class TransportView: UIView {
    
    let topBorder = CALayer()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        topBorder.backgroundColor = UIColor.separator.cgColor
        layer.addSublayer(topBorder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scaleFactor = window?.screen.scale ?? 1
        topBorder.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1 / scaleFactor)
    }
}
