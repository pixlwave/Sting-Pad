import UIKit
import MediaPlayer

class StkController: UIViewController {
    
    private let engine = Engine.sharedClient
    
    @IBOutlet weak var playlistTable: UITableView!
    @IBOutlet weak var ipodShuffleButton: UIButton!
    @IBOutlet weak var ipodPlayButton: UIButton!
    @IBOutlet weak var stingScrollView: UIScrollView!
    @IBOutlet weak var stingPageControl: UIPageControl!
    @IBOutlet weak var playingLabel: UILabel!
    
    // array to hold the sting views
    private var stingViews = [StingView]()
    private var selectedSting = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make self delegate for sting players
        engine.setStingDelegates(self)
        
        // puts yellow view under status bar on iOS 7, handling Insets for correct scrolling
        if #available(iOS 7, *) {
            if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                playlistTable.contentInset = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.height, playlistTable.contentInset.left, playlistTable.contentInset.bottom, playlistTable.contentInset.right)
                playlistTable.scrollIndicatorInsets = UIEdgeInsetsMake(UIApplication.sharedApplication().statusBarFrame.height, playlistTable.contentInset.left, playlistTable.contentInset.bottom, playlistTable.contentInset.right)
                let statusBarView = UIView(frame: UIApplication.sharedApplication().statusBarFrame)
                statusBarView.backgroundColor = view.backgroundColor
                view.addSubview(statusBarView)
            }
        }

        // control of the table
        playlistTable.delegate = self
        playlistTable.dataSource = self
        
        // and get screen width for positioning
        let screenWidth = UIScreen.mainScreen().bounds.width
        
        // add sting views to sting scroll view
        for i in 0..<engine.sting.count {
            let v = StingView(frame: CGRect(x: CGFloat(i) * screenWidth, y: 0, width: screenWidth, height: stingScrollView.frame.height))
            v.playButton.addTarget(self, action: #selector(play), forControlEvents: .TouchDown)
            v.stopButton.addTarget(self, action: #selector(stop), forControlEvents: .TouchUpInside)
            v.titleLabel.text = engine.sting[i].title
            stingViews.append(v)
            
            stingScrollView.addSubview(stingViews[i])
        }
        
        // set up scroll view for playing stings
        stingScrollView.contentSize = CGSize(width: stingViews.last!.frame.origin.x + stingViews.last!.frame.width, height: stingViews.first!.frame.height)
        stingScrollView.delaysContentTouches = false    // prevents scroll view from momentarily blocking the play button's action
        stingScrollView.delegate = self
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // listen for iPod playback changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateTable), name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playbackStateDidChange(_:)), name: MPMusicPlayerControllerPlaybackStateDidChangeNotification, object: nil)
        
        // listen for iPod library changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshPlaylists), name:MPMediaLibraryDidChangeNotification, object: nil)
        
        // update shuffle button in case changed outside of app
        #if !(arch(i386) || arch(x86_64)) && os(iOS)
            ipodShuffleButton.selected = engine.ipod.shuffleState   // TODO: observe this?
        #endif
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (Defaults["walkthroughVersionSeen"].double ?? 0.0) < WalkthroughController.currentVersion {
            showWalkthrough()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // remove all observers when view isn't visable (because someone said so)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let navC = segue.destinationViewController as? UINavigationController, loadVC = navC.topViewController as? StingController where segue.identifier == "LoadSting" {
            loadVC.stingIndex = selectedSting
        }
    }
    
    func play() {
        // plays selected sting (from sting scroll view) and shows that it's playing
        engine.playSting(selectedSting)
        playingLabel.hidden = false
    }
    
    func stop() {
        // stops and hides the playing label
        engine.stopSting()
        playingLabel.hidden = true
    }
    
    @IBAction func ipodPlayPause() {
        // handle play/pause properly
        if engine.ipod.isPlaying {
            engine.pauseiPod()
        } else {
            engine.playiPod()
            playingLabel.hidden = true   // remove sting playing label (should go in the engine probably)
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
        ipodShuffleButton.selected = engine.ipod.shuffleState
    }
    
    func updateStingTitles() {
        // get titles from stings
        for (i, v) in stingViews.enumerate() {
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
    
    func playbackStateDidChange(notification: NSNotification) {
        updatePlayPause()
        
        // correct (but buggy) alternative here:
        // http://stackoverflow.com/questions/1324409/mpmusicplayercontroller-stops-sending-notifications
    }
    
    func updatePlayPause() {
        ipodPlayButton.selected = engine.ipod.isPlaying
    }
    
    func playlistDidChange() {
        // called when user selects new playlist
        updateTable()
    }
    
    func showWalkthrough() {
        // instantiate walkthrough controller and present
        let walkSB = UIStoryboard(name: "Walkthrough", bundle: nil)
        if let walkVC = walkSB.instantiateViewControllerWithIdentifier("WalkthroughController") as? WalkthroughController {
            walkVC.modalTransitionStyle = .CrossDissolve
            presentViewController(walkVC, animated:true, completion:nil)
            
            // record the version being seen to allow ui updates to be shown in future versions
            Defaults["walkthroughVersionSeen"] = WalkthroughController.currentVersion
        }
    }
}

// MARK: StingDelegate
extension StkController: StingDelegate {
    func stingHasStopped(sting: Sting) {
        stop()
    }
}

// MARK: UITableViewDataSource
extension StkController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let playlist = engine.ipod.playlist {
            return playlist.count
        } else {
            return 0   // returned if the library/playist is non-existent
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // let reuseIdentifier ||= "TrackCell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Track Cell") ?? UITableViewCell(style: .Subtitle, reuseIdentifier: "Track Cell")
        
        // ensure library/playlist contains songs
        if let playlist = engine.ipod.playlist where playlist.count > 0 {
            // get song for index path
            let song = playlist.items[indexPath.row]
            
            // fill out cell as appropriate
            cell.textLabel?.text = song.valueForProperty(MPMediaItemPropertyTitle) as? String
            cell.detailTextLabel?.text = song.valueForProperty(MPMediaItemPropertyArtist) as? String
            
            if let artwork = song.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                cell.imageView?.image = artwork.imageWithSize(CGSize(width: 55, height: 55))
            } else {
                cell.imageView?.image = UIImage(named: "albumartblank")
            }
            
            // need to implement a better way of doing this that doesn't call updateTable every time a track changes???
            // color the now playing song in orange (slightly darker than the main orange for balance)
            if song == engine.ipod.nowPlayingItem() {
                cell.textLabel?.textColor = UIColor(hue: 30/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
                cell.detailTextLabel?.textColor = UIColor(hue: 34/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
            } else {
                cell.textLabel?.textColor = UIColor.darkTextColor()
                cell.detailTextLabel?.textColor = UIColor.darkTextColor()
            }
        }
        
        return cell
    }
}

// MARK: UITableViewDelegate
extension StkController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // play selected song
        engine.playiPodItem(indexPath.row)
        
        // hides sting playing label
        // needs a more "universal" way of calling stop (move from engine to here?)
        playingLabel.hidden = true
        
        // clear selection
        tableView.deselectRowAtIndexPath(indexPath, animated:true)
    }
}

// MARK: UIScrollViewDelegate
extension StkController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // update selected sting when sting scroll view has completed animating
        if scrollView == stingScrollView {
            selectedSting = Int(scrollView.contentOffset.x / scrollView.frame.width)
            stingPageControl.currentPage = selectedSting
        }
    }
}
