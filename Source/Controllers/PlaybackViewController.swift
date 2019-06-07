import UIKit
import MediaPlayer

class PlaybackViewController: UICollectionViewController {
    
    private let engine = Engine.shared
    private var transportView: TransportView?
    private var cuedSting = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.stingDelegate = self
        
        let transportView = TransportView(frame: .zero)
        transportView.playButton.addTarget(self, action: #selector(playSting), for: .touchUpInside)
        transportView.stopButton.addTarget(self, action: #selector(stopSting), for: .touchUpInside)
        transportView.previousButton.addTarget(self, action: #selector(previousSting), for: .touchUpInside)
        transportView.nextButton.addTarget(self, action: #selector(nextSting), for: .touchUpInside)
        view.addSubview(transportView)
        self.transportView = transportView
        
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
        let origin = CGPoint(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - TransportView.defaultHeight)
        let size = CGSize(width: view.frame.width, height: TransportView.defaultHeight)
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
    
    @objc func playSting() {
        engine.playSting(cuedSting)
        nextSting()
    }
    
    @objc func stopSting() {
        engine.stopSting()
    }
    
    @objc func nextSting() {
        stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = false
        cuedSting = (cuedSting + 1) % engine.show.stings.count
        stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = true
    }
    
    @objc func previousSting() {
        if cuedSting > 0 {
            stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = false
            cuedSting = cuedSting - 1 % engine.show.stings.count
            stingCellForItem(at: IndexPath(item: cuedSting, section: 0))?.isCued = true
        }
    }
    
    func stingCellForItem(at indexPath: IndexPath) -> StingCell? {
        return collectionView.cellForItem(at: indexPath) as? StingCell
    }
    
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
        if (collectionView.cellForItem(at: indexPath) as? StingCell)?.isPlaying != true {
            engine.playSting(indexPath.item)
        } else {
            engine.rewindSting(indexPath.item)
        }
    }
    
}


// MARK: StingDelegate
extension PlaybackViewController: StingDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        let index = engine.show.stings.firstIndex(of: sting)
        (collectionView.cellForItem(at: IndexPath(item: index ?? 0, section: 0)) as? StingCell)?.isPlaying = true
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        let index = engine.show.stings.firstIndex(of: sting)
        (collectionView.cellForItem(at: IndexPath(item: index ?? 0, section: 0)) as? StingCell)?.isPlaying = false
    }
}
