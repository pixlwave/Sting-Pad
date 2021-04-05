import UIKit

class WaveformMarkerView: UIView {
    
    private let lineView = UIView()
    private let handleView = UIView()           // view with gesture recogniser
    private let handleCircleView = UIView()     // smaller view to render circle
    
    let dragRecogniser = UIPanGestureRecognizer()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        handleView.addGestureRecognizer(dragRecogniser)
        
        addSubview(lineView)
        addSubview(handleView)
        handleView.addSubview(handleCircleView)
    }
    
    override func tintColorDidChange() {
        lineView.backgroundColor = tintColor
        handleView.backgroundColor = .clear
        handleCircleView.backgroundColor = tintColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let handleRadius = bounds.width / 4
        
        lineView.frame = CGRect(x: bounds.midX - 1, y: 0, width: 2, height: bounds.height - (bounds.width / 2))
        handleView.frame = CGRect(x: 0, y: bounds.height - bounds.width, width: bounds.width, height: bounds.width)
        handleCircleView.frame = handleView.bounds.insetBy(dx: handleRadius, dy: handleRadius)
        handleCircleView.layer.cornerRadius = handleRadius
    }
    
}
