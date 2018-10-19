import UIKit

class WelcomeViewController: UIViewController {
    static let currentVersion = 2.0
    
    // image names and info text
    let images = ["ThankYou", "Playlist", "Sting", "Settings"]
    
    var currentImage = 0
    
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSpaceConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start at the beginning and load first image
        imageView.image = UIImage(named: "Welcome-\(images[currentImage])")
        progressLabel.text = "\(currentImage + 1) of \(images.count)"
        
        if UIScreen.main.bounds.height < 568 {
            labelSpaceConstraint.constant = 3
            imageTopConstraint.constant = 10
            bottomSpaceConstraint.constant = 0
        }
    }
    
    @IBAction func screenTapped() {
        // go to the next image until end, then dismiss self
        currentImage += 1
        if currentImage < images.count {
            UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.imageView.image = UIImage(named: "Welcome-\(self.images[self.currentImage])")
            })
            UIView.transition(with: progressLabel, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.progressLabel.text = "\(self.currentImage + 1) of \(self.images.count)"
            })
        } else {
            modalTransitionStyle = .coverVertical
            presentingViewController!.dismiss(animated: true, completion: nil)
        }
    }
}
