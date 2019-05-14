import UIKit
import MediaPlayer

class MainViewController: UICollectionViewController {
    
    private let engine = Engine.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.setStingDelegates(self)
        
        // prevents scroll view from momentarily blocking the play button's action
        collectionView.delaysContentTouches = false; #warning("Test if this works or if the property needs to be set on the scroll view")
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name("Stings Did Change"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "WelcomeVersionSeen") < WelcomeViewController.currentVersion {
            showWelcomeScreen()
        }
    }
    
    @IBAction func addSting(_ sender: UIBarButtonItem) {
        engine.addSting()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Sting Settings", let stingVC = segue.destination as? StingViewController, let button = sender as? UIButton {
            stingVC.stingIndex = button.tag
        }
    }
    
    @IBAction func play(_ sender: UIButton) {
        // plays selected sting and shows that it's playing
        engine.playSting(sender.tag)
    }
    
    @IBAction func stop(_ sender: UIButton) {
        // stops and hides the playing label
        engine.stopSting()
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
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return engine.stings.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Sting Cell", for: indexPath)
        
        guard let stingCell = cell as? StingCell else { return cell }
        
        stingCell.titleLabel.text = engine.stings[indexPath.item].title
        stingCell.playButton.tag = indexPath.item
        stingCell.settingsButton.tag = indexPath.item
        
        return stingCell
    }
}


// MARK: StingDelegate
extension MainViewController: StingDelegate {
    func stingDidStartPlaying(_ sting: Sting) {
        let index = engine.stings.firstIndex(of: sting)
        (collectionView.cellForItem(at: IndexPath(item: index ?? 0, section: 0)) as? StingCell)?.playingLabel.isHidden = false
    }
    
    func stingDidStopPlaying(_ sting: Sting) {
        let index = engine.stings.firstIndex(of: sting)
        (collectionView.cellForItem(at: IndexPath(item: index ?? 0, section: 0)) as? StingCell)?.playingLabel.isHidden = true
    }
}
