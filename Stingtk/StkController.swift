import UIKit
import MediaPlayer

class StkController: UIViewController {
    
    fileprivate let engine = Engine.sharedClient
    
    @IBOutlet weak var playlistTable: UITableView!
    @IBOutlet weak var ipodShuffleButton: UIButton!
    @IBOutlet weak var ipodPlayButton: UIButton!
    @IBOutlet weak var stingScrollView: UIScrollView!
    @IBOutlet weak var stingPageControl: UIPageControl!
    @IBOutlet weak var playingLabel: UILabel!
    
    // array to hold the sting views
    private var stingViews = [StingView]()
    fileprivate var selectedSting = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.setStingDelegates(self)
        
        // puts yellow view under status bar on iOS 7, handling Insets for correct scrolling
        if #available(iOS 7, *) {
            if UIDevice.current.userInterfaceIdiom != .pad {
                playlistTable.contentInset = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.height, playlistTable.contentInset.left, playlistTable.contentInset.bottom, playlistTable.contentInset.right)
                playlistTable.scrollIndicatorInsets = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.height, playlistTable.contentInset.left, playlistTable.contentInset.bottom, playlistTable.contentInset.right)
                let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
                statusBarView.backgroundColor = view.backgroundColor
                view.addSubview(statusBarView)
            }
        }

        // control of the table
        playlistTable.delegate = self
        playlistTable.dataSource = self
        
        // and get screen width for positioning
        let screenWidth = UIScreen.main.bounds.width
        
        // add sting views to sting scroll view
        for i in 0..<engine.sting.count {
            let v = StingView(frame: CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: stingScrollView.frame.height))
            v.playButton.addTarget(self, action: #selector(play), for: .touchDown)
            v.stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
            v.titleLabel.text = engine.sting[i].title
            stingViews.append(v)
            
            stingScrollView.addSubview(stingViews[i])
        }
        
        // set up scroll view for playing stings
        stingScrollView.contentSize = CGSize(width: stingViews.last!.frame.origin.x + stingViews.last!.frame.width, height: stingViews.first!.frame.height)
        stingScrollView.delaysContentTouches = false    // prevents scroll view from momentarily blocking the play button's action
        stingScrollView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen for iPod playback changes
        NotificationCenter.default.addObserver(self, selector: #selector(updateTable), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateDidChange(_:)), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        
        // listen for iPod library changes
        NotificationCenter.default.addObserver(self, selector: #selector(refreshPlaylists), name:NSNotification.Name.MPMediaLibraryDidChange, object: nil)
        
        // update shuffle button in case changed outside of app
        #if !(arch(i386) || arch(x86_64)) && os(iOS)
            ipodShuffleButton.isSelected = engine.ipod.shuffleState   // TODO: observe this?
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "walkthroughVersionSeen") < WalkthroughController.currentVersion {
            showWalkthrough()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove all observers when view isn't visable (because someone said so)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navC = segue.destination as? UINavigationController, let loadVC = navC.topViewController as? StingController, segue.identifier == "LoadSting" {
            loadVC.stingIndex = selectedSting
        }
    }
    
    func play() {
        // plays selected sting (from sting scroll view) and shows that it's playing
        engine.playSting(selectedSting)
        playingLabel.isHidden = false
    }
    
    func stop() {
        // stops and hides the playing label
        engine.stopSting()
        playingLabel.isHidden = true
    }
    
    @IBAction func ipodPlayPause() {
        // handle play/pause properly
        if engine.ipod.isPlaying {
            engine.pauseiPod()
        } else {
            engine.playiPod()
            playingLabel.isHidden = true   // remove sting playing label (should go in the engine probably)
        }
    }
    
    @IBAction func ipodPrevious() {
        engine.ipod.previous()
    }
    
    @IBAction func ipodNext() {
        engine.ipod.next()
    }
    
    @IBAction func ipodShuffle() {
        engine.ipod.toggleShuffle()
        ipodShuffleButton.isSelected = engine.ipod.shuffleState
    }
    
    func updateStingTitles() {
        // get titles from stings
        for (i, v) in stingViews.enumerated() {
            v.titleLabel.text = engine.sting[i].title
        }
    }
    
    func refreshPlaylists() {
        // called when ipod library changes
        engine.ipod.refreshPlaylists()
        updateTable()
    }
    
    func updateTable() {
        playlistTable.reloadData()
    }
    
    func playbackStateDidChange(_ notification: Notification) {
        updatePlayPause()
        
        // correct (but buggy) alternative here:
        // http://stackoverflow.com/questions/1324409/mpmusicplayercontroller-stops-sending-notifications
    }
    
    func updatePlayPause() {
        ipodPlayButton.isSelected = engine.ipod.isPlaying
    }
    
    func playlistDidChange() {
        // called when user selects new playlist
        updateTable()
    }
    
    func showWalkthrough() {
        // instantiate walkthrough controller and present
        let walkSB = UIStoryboard(name: "Walkthrough", bundle: nil)
        if let walkVC = walkSB.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughController {
            walkVC.modalTransitionStyle = .crossDissolve
            present(walkVC, animated:true, completion:nil)
            
            // record the version being seen to allow ui updates to be shown in future versions
            UserDefaults.standard.set(WalkthroughController.currentVersion, forKey: "walkthroughVersionSeen")
        }
    }
}

// MARK: StingDelegate
extension StkController: StingDelegate {
    func stingHasStopped(_ sting: Sting) {
        stop()
    }
}

// MARK: UITableViewDataSource
extension StkController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let playlist = engine.ipod.playlist {
            return playlist.count
        } else {
            return 0   // returned if the library/playist is non-existent
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // let reuseIdentifier ||= "TrackCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Track Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Track Cell")
        
        // ensure library/playlist contains songs
        if let playlist = engine.ipod.playlist, playlist.count > 0 {
            // get song for index path
            let song = playlist.items[indexPath.row]
            
            // fill out cell as appropriate
            cell.textLabel?.text = song.value(forProperty: MPMediaItemPropertyTitle) as? String
            cell.detailTextLabel?.text = song.value(forProperty: MPMediaItemPropertyArtist) as? String
            
            if let artwork = song.value(forProperty: MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                cell.imageView?.image = artwork.image(at: CGSize(width: 55, height: 55))
            } else {
                cell.imageView?.image = UIImage(named: "albumartblank")
            }
            
            // need to implement a better way of doing this that doesn't call updateTable every time a track changes???
            // color the now playing song in orange (slightly darker than the main orange for balance)
            if song == engine.ipod.nowPlayingItem() {
                cell.textLabel?.textColor = UIColor(hue: 30/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
                cell.detailTextLabel?.textColor = UIColor(hue: 34/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
            } else {
                cell.textLabel?.textColor = UIColor.darkText
                cell.detailTextLabel?.textColor = UIColor.darkText
            }
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension StkController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // play selected song
        engine.playiPodItem(indexPath.row)
        
        // hides sting playing label
        // needs a more "universal" way of calling stop (move from engine to here?)
        playingLabel.isHidden = true
        
        // clear selection
        tableView.deselectRow(at: indexPath, animated:true)
    }
}

// MARK: UIScrollViewDelegate
extension StkController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // update selected sting when sting scroll view has completed animating
        if scrollView == stingScrollView {
            selectedSting = Int(scrollView.contentOffset.x / scrollView.frame.width)
            stingPageControl.currentPage = selectedSting
        }
    }
}
