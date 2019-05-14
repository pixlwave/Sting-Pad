import UIKit
import MediaPlayer

class MainViewController: UIViewController {
    
    fileprivate let engine = Engine.shared
    
    @IBOutlet weak var stingScrollView: UIScrollView!
    @IBOutlet weak var stingPageControl: UIPageControl!
    @IBOutlet weak var playingLabel: UILabel!
    
    // array to hold the sting views
    private var stingViews = [StingView]()
    
    fileprivate var selectedSting = 0
    fileprivate var scrollPosition = UITableView.ScrollPosition.top

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.setStingDelegates(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // and get screen width for positioning
        let viewWidth = view.bounds.width
        
        // add sting views to sting scroll view
        for i in 0..<engine.stings.count {
            let v = StingView(frame: CGRect(x: CGFloat(i) * viewWidth, y: 0, width: viewWidth, height: stingScrollView.frame.height))
            v.playButton.addTarget(self, action: #selector(play), for: .touchDown)
            v.stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
            v.titleLabel.text = engine.stings[i].title
            stingViews.append(v)
            
            stingScrollView.addSubview(stingViews[i])
        }
        
        // set up scroll view for playing stings
        stingScrollView.contentSize = CGSize(width: stingViews.last!.frame.origin.x + stingViews.last!.frame.width, height: stingViews.first!.frame.height)
        stingScrollView.delaysContentTouches = false    // prevents scroll view from momentarily blocking the play button's action
        stingScrollView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "WelcomeVersionSeen") < WelcomeViewController.currentVersion {
            showWelcomeScreen()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoadSting", let navC = segue.destination as? UINavigationController, let loadVC = navC.topViewController as? StingViewController {
            loadVC.stingIndex = selectedSting
        }
    }
    
    @objc func play() {
        // plays selected sting (from sting scroll view) and shows that it's playing
        engine.playSting(selectedSting)
    }
    
    @objc func stop() {
        // stops and hides the playing label
        engine.stopSting()
    }
    
    func updateStingTitles() {
        // get titles from stings
        for (i, v) in stingViews.enumerated() {
            v.titleLabel.text = engine.stings[i].title
        }
    }
    
    func showWelcomeScreen() {
        // instantiate welcome controller and present
        let walkSB = UIStoryboard(name: "Welcome", bundle: nil)
        if let walkVC = walkSB.instantiateViewController(withIdentifier: "Welcome") as? WelcomeViewController {
            walkVC.modalTransitionStyle = .crossDissolve
            present(walkVC, animated:true, completion:nil)
            
            // record the version being seen to allow ui updates to be shown in future versions
            UserDefaults.standard.set(WelcomeViewController.currentVersion, forKey: "WelcomeVersionSeen")
        }
    }
}


// MARK: StingDelegate
extension MainViewController: StingDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        playingLabel.isHidden = false
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        playingLabel.isHidden = true
    }
}


// MARK: UIScrollViewDelegate
extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // update selected sting when sting scroll view has completed animating
        if scrollView == stingScrollView {
            selectedSting = Int(scrollView.contentOffset.x / scrollView.frame.width)
            stingPageControl.currentPage = selectedSting
        }
    }
}
