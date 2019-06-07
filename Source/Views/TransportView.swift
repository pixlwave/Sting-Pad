import UIKit

class TransportView: UIView {
    
    static var defaultHeight: CGFloat = 90
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
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
        let nibName = String(describing: TransportView.self)
        let nib = UINib(nibName: nibName, bundle:nil)
        nib.instantiate(withOwner: self, options:nil)
        
        // add the view loaded from the nib into self.
        self.addSubview(self.view)
    }
    
}
