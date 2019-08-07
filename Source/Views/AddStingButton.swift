import UIKit

class AddStingButton: UIControl {
    
    let shape = CAShapeLayer()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.secondaryLabel.cgColor
        shape.lineWidth = 4
        shape.lineDashPattern = [8, 8]
        layer.addSublayer(shape)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shape.path = CGPath(roundedRect: bounds.insetBy(dx: shape.lineWidth, dy: shape.lineWidth), cornerWidth: 8, cornerHeight: 8, transform: nil)
    }
    
}
