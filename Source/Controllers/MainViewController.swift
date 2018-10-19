import UIKit
import MediaPlayer

class MainViewController: UIViewController {
    
    fileprivate let engine = Engine.shared
    
    @IBOutlet weak var playlistTable: UITableView!
    @IBOutlet weak var ipodShuffleButton: UIButton!
    @IBOutlet weak var ipodPlayButton: UIButton!
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

        // control of the table
        playlistTable.delegate = self
        playlistTable.dataSource = self
        playlistTable.contentInset.bottom = 49
        
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
        
        // listen for iPod library changes (includes now playing track changes)
        NotificationCenter.default.addObserver(self, selector: #selector(ipodDidChange(notification:)), name: .MPMediaLibraryDidChange, object: nil)
        
        // listen for iPod playback changes
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStateDidChange(_:)), name:  .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        
        // update shuffle button in case changed outside of app
        if engine.ipod.shuffleState {
            ipodShuffleButton.setImage(#imageLiteral(resourceName: "shuffle_selected"), for: .normal)
            scrollPosition = .middle
        } else {
            ipodShuffleButton.setImage(#imageLiteral(resourceName: "shuffle"), for: .normal)
            scrollPosition = .top
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.double(forKey: "walkthroughVersionSeen") < WalkthroughViewController.currentVersion {
            showWalkthrough()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove all observers when view isn't visable (because someone said so)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoadSting", let navC = segue.destination as? UINavigationController, let loadVC = navC.topViewController as? StingViewController {
            loadVC.stingIndex = selectedSting
        }
    }
    
    @objc func play() {
        // plays selected sting (from sting scroll view) and shows that it's playing
        engine.playSting(selectedSting)
        playingLabel.isHidden = false
    }
    
    @objc func stop() {
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
        
        if engine.ipod.shuffleState {
            ipodShuffleButton.setImage(#imageLiteral(resourceName: "shuffle_selected"), for: .normal)
            scrollPosition = .middle
        } else {
            ipodShuffleButton.setImage(#imageLiteral(resourceName: "shuffle"), for: .normal)
            scrollPosition = .top
        }
    }
    
    func updateStingTitles() {
        // get titles from stings
        for (i, v) in stingViews.enumerated() {
            v.titleLabel.text = engine.sting[i].title
        }
    }
    
    func playlistDidChange() {
        // called when user selects new playlist
        playlistTable.reloadData()
    }
    
    @objc func ipodDidChange(notification: Notification) {
        // called when ipod library changes or a new track plays
        engine.ipod.refreshPlaylists()
        
        if playlistTable.numberOfRows(inSection: 0) == engine.ipod.playlist?.count, let visibleIndexPaths = playlistTable.indexPathsForVisibleRows {
            playlistTable.reloadRows(at: visibleIndexPaths, with: .none); #warning("this seems excessive for a track change")
        } else {
            playlistTable.reloadData()
        }
        
        scrollToCurrentItem()
    }
    
    @objc func playbackStateDidChange(_ notification: Notification) {
        updatePlayPause()
        
        // correct (but buggy) alternative here:
        // http://stackoverflow.com/questions/1324409/mpmusicplayercontroller-stops-sending-notifications
    }
    
    func updatePlayPause() {
        if engine.ipod.isPlaying {
            ipodPlayButton.setImage(#imageLiteral(resourceName: "ipodpause.png"), for: .normal)
        } else {
            ipodPlayButton.setImage(#imageLiteral(resourceName: "ipodplay"), for: .normal)
        }
    }
    
    func scrollToCurrentItem() {
        guard let nowPlayingItemIndex = engine.ipod.nowPlayingItemIndex else { return }
        let indexPath = IndexPath(row: nowPlayingItemIndex, section: 0)
        
        if playlistTable.indexPathsForVisibleRows?.dropLast(2).contains(indexPath) != true {
            playlistTable.scrollToRow(at: indexPath, at: scrollPosition, animated: true)
        }
    }
    
    func showWalkthrough() {
        // instantiate walkthrough controller and present
        let walkSB = UIStoryboard(name: "Walkthrough", bundle: nil)
        if let walkVC = walkSB.instantiateViewController(withIdentifier: "WalkthroughController") as? WalkthroughViewController {
            walkVC.modalTransitionStyle = .crossDissolve
            present(walkVC, animated:true, completion:nil)
            
            // record the version being seen to allow ui updates to be shown in future versions
            UserDefaults.standard.set(WalkthroughViewController.currentVersion, forKey: "walkthroughVersionSeen")
        }
    }
}


// MARK: StingDelegate
extension MainViewController: StingDelegate {
    func stingHasStopped(_ sting: Sting) {
        stop()
    }
}


// MARK: UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let playlist = engine.ipod.playlist {
            return playlist.count
        } else {
            return 0   // returned if the library/playist is non-existent
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Song Cell") as? SongCell ?? SongCell()
        
        // ensure library/playlist contains songs
        if let playlist = engine.ipod.playlist, playlist.count > 0 {
            // get song for index path
            let song = playlist.items[indexPath.row]
            
            // fill out cell as appropriate
            cell.titleLabel?.text = song.title
            cell.artistLabel?.text = song.artist
            
            if let artwork = song.artwork {
                cell.albumArtImageView?.image = artwork.image(at: CGSize(width: 55, height: 55))
            } else {
                cell.albumArtImageView?.image = #imageLiteral(resourceName: "albumartblank.png")
            }
            
            // color the now playing song
            cell.isPlaying = (song == engine.ipod.nowPlayingItem())
        }
        
        return cell
    }
}


// MARK: UITableViewDelegate
extension MainViewController: UITableViewDelegate {
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
extension MainViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // update selected sting when sting scroll view has completed animating
        if scrollView == stingScrollView {
            selectedSting = Int(scrollView.contentOffset.x / scrollView.frame.width)
            stingPageControl.currentPage = selectedSting
        }
    }
}
