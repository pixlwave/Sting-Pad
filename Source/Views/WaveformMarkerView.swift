import UIKit

class WaveformMarkerView: UIView {
    
    private let lineView = UIView()
    private let handleView = UIView()
    
    let dragRecogniser = UIPanGestureRecognizer()
    let color = UIColor.tintColor
    let width: CGFloat = 20
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    private func setup() {
        lineView.backgroundColor = color
        handleView.backgroundColor = color
        handleView.addGestureRecognizer(dragRecogniser)
        
        addSubview(lineView)
        addSubview(handleView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let handleRadius = bounds.width / 2
        
        lineView.frame = CGRect(x: bounds.midX - 1, y: 0, width: 2, height: bounds.height - handleRadius)
        handleView.frame = CGRect(x: 0, y: bounds.height - 2 * handleRadius, width: 2 * handleRadius, height: 2 * handleRadius)
        handleView.layer.cornerRadius = handleRadius
    }
    
}
