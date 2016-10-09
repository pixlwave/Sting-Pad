import UIKit

class StingView: UIView {
    
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
        view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: frame.size)  // this works, but can it be implied by design. Or rename as contentView?
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
        view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: frame.size)  // where does this frame come from?
    }
    
    func loadNib() {
        // load the contents of the nib
        // let nibName = NSStringFromClass(self)
        let nibName = "StingView"
        let nib = UINib(nibName: nibName, bundle:nil)
        nib.instantiate(withOwner: self, options:nil)
        
        // add the view loaded from the nib into self.
        self.addSubview(self.view)
    }
}
