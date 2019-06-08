import UIKit
import MediaPlayer

class PlaybackViewController: UICollectionViewController {
    
    private let engine = Engine.shared
    private var cuedSting = 0
    
    @IBOutlet var transportView: UIView!
    private let transportViewHeight: CGFloat = 90
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.stingDelegate = self
        
        // load the transport view nib and add as a subview via it's outlet
        Bundle.main.loadNibNamed("TransportView", owner: self, options: nil)
        view.addSubview(transportView)
        
        // prevents scroll view from momentarily blocking the play button's action
        collectionView.delaysContentTouches = false; #warning("Test if this works or if the property needs to be set on the scroll view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .stingsDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "WelcomeVersionSeen") < WelcomeViewController.currentVersion {
            showWelcomeScreen()
        }
    }
    
    override func viewWillLayoutSubviews() {
        let origin = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - transportViewHeight)
        let size = CGSize(width: view.frame.width, height: transportViewHeight)
        transportView?.frame = CGRect(origin: origin, size: size)
        collectionView.contentInset.bottom = size.height
    }
    
    #warning("Implement more efficient responses to changed data.")
    @objc func reloadData() {
        collectionView.reloadData()
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
    
    @IBAction func playSting() {
        engine.playSting(cuedSting)
        nextSting()
    }
    
    @IBAction func stopSting() {
        engine.stopSting()
    }
    
    @IBAction func nextSting() {
        stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = false
        cuedSting = (cuedSting + 1) % engine.show.stings.count
        stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = true
    }
    
    @IBAction func previousSting() {
        if cuedSting > 0 {
            stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = false
            cuedSting = cuedSting - 1 % engine.show.stings.count
            stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = true
        }
    }
    
    func stingCellForItem(at indexPath: IndexPath) -> StingCell? {
        return collectionView.cellForItem(at: indexPath) as? StingCell
    }
    
    // MARK: UICollectionViewDataSource/Delegate
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return engine.show.stings.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Sting Cell", for: indexPath)
        
        guard let stingCell = cell as? StingCell else { return cell }
        
        stingCell.titleLabel.text = engine.show.stings[indexPath.item].title
        stingCell.isCued = indexPath.item == cuedSting
        
        return stingCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if stingCellForItem(at: indexPath)?.isPlaying != true {
            engine.playSting(indexPath.item)
        } else {
            engine.rewindSting(indexPath.item)
        }
    }
    
}


// MARK: StingDelegate
extension PlaybackViewController: StingDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        guard let index = engine.show.stings.firstIndex(of: sting) else { return }
        stingCellForItem(at: IndexPath(item: index, section: 0))?.isPlaying = true
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        guard let index = engine.show.stings.firstIndex(of: sting) else { return }
        stingCellForItem(at: IndexPath(item: index, section: 0))?.isPlaying = false
    }
}
