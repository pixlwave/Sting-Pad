import UIKit

class WalkthroughController: UIViewController {
    static let currentVersion = 1.1
    
    // image names and info text
    let images = ["ThankYou", "Playlist", "Sting", "Settings"]
    
    var currentImage = 0
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var walkthroughImageView: UIImageView!
    @IBOutlet weak var labelSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start at the beginning and load first image
        walkthroughImageView.image = UIImage(named: "Walkthrough\(images[currentImage])")
        progressLabel.text = "\(currentImage + 1) of \(images.count)"
        
        if UIScreen.mainScreen().bounds.height < 568 {
            labelSpaceConstraint.constant = 3
            imageTopConstraint.constant = 10
            bottomSpaceConstraint.constant = 0
        }
    }
    
    @IBAction func screenTapped() {
        // go to the next image until end, then dismiss self
        currentImage += 1
        if currentImage < images.count {
            UIView.transitionWithView(walkthroughImageView, duration: 0.2, options: .TransitionCrossDissolve, animations: { self.walkthroughImageView.image = UIImage(named: "Walkthrough\(self.images[self.currentImage])") }, completion: nil)
            UIView.transitionWithView(progressLabel, duration: 0.2, options: .TransitionCrossDissolve, animations: { self.progressLabel.text = "\(self.currentImage + 1) of \(self.images.count)" }, completion: nil)
        } else {
            modalTransitionStyle = .CoverVertical
            presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}