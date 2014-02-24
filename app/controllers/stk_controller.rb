class StkController < UIViewController
  extend IB

  outlet :titleLabel0, UILabel
  outlet :titleLabel1, UILabel
  outlet :titleLabel2, UILabel
  outlet :playlistTable, UITableView
  outlet :ipodPlayButton, UIButton
  outlet :stingScrollView, UIScrollView
  outlet :stingView, UIView
  outlet :stingPage, UIPageControl

  def viewDidLoad

    @engine = Engine.sharedClient

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      @playlistTable.setContentInset(UIEdgeInsetsMake(20, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
      @statusBarView = UIView.alloc.initWithFrame(UIApplication.sharedApplication.statusBarFrame)
      @statusBarView.backgroundColor = self.view.backgroundColor
      self.view.addSubview(@statusBarView)
    end

    @playlistTable.delegate = self
    @playlistTable.dataSource = self

    @stingScrollView.setContentSize(@stingView.frame.size)
    @stingScrollView.delaysContentTouches = false
    @stingScrollView.delegate = self
    @selectedSting = 0

    updateStingTitles

  end

  def viewWillAppear(animated)

    # @ipodObserver = App.notification_center.observe MPMusicPlayerControllerNowPlayingItemDidChangeNotification do |notification|
    #   self.performSelector(updateTable, withObject:self, afterDelay:1)
    #   App.alert("Notified")
    # end

    NSNotificationCenter.defaultCenter.addObserver(self, selector:'updateTable', name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object:nil)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'playbackStateDidChange:', name:MPMusicPlayerControllerPlaybackStateDidChangeNotification, object:nil)

  end

  def viewDidAppear(animated)

    showWalkthrough unless Turnkey.unarchive("hasSeenTutorial")

  end

  def viewWillDisappear(animated)
  
    NSNotificationCenter.defaultCenter.removeObserver(self)
  
  end

  def play

    @engine.playSting(@selectedSting)

  end

  def stop

    @engine.stopSting

  end

  def iPodPlayPause

    if ipodIsPlaying
      @engine.pauseiPod
    else
      @engine.playiPod
    end

  end

  # def iPodPlay

  #   @engine.playiPod

  # end

  # def iPodPause

  #   @engine.pauseiPod

  # end

  def iPodPrevious

    @engine.ipod.previous

  end

  def iPodNext

    @engine.ipod.next

  end

  def updateStingTitles

    @titleLabel0.text = @engine.sting[0].title
    @titleLabel1.text = @engine.sting[1].title
    @titleLabel2.text = @engine.sting[2].title

  end

  def updateTable

    @playlistTable.reloadData

  end

  def playbackStateDidChange(notification)

    state = notification.userInfo.objectForKey("MPMusicPlayerControllerPlaybackStateKey")

    if state == MPMusicPlaybackStatePlaying
      @ipodPlayButton.setTitle("Pause", forState:UIControlStateNormal)
    else
      @ipodPlayButton.setTitle("Play", forState:UIControlStateNormal)
    end

  end

# - (void)playbackStateDidChange:(NSNotification *)notification {
#     static NSString * const stateKey = @"MPMusicPlayerControllerPlaybackStateKey";
#     NSNumber *number = [[notification userInfo] objectForKey:stateKey];
#     MPMusicPlaybackState state = [number integerValue];
#     // state is the new state
#     MPMusicPlayerController *player = [notification object];
#     // state may not be equal to player.playbackState
# }

  def showWalkthrough

    walkvc = storyboard.instantiateViewControllerWithIdentifier("WalkthroughController")
    walkvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve
    presentViewController(walkvc, animated:true, completion:nil)
    Turnkey.archive(true, "hasSeenTutorial")

  end

  def ipodIsPlaying

    if @engine.ipod.playbackState == MPMusicPlaybackStatePlaying
      return true
    else
      return false
    end

  end


  ##### Table View delegate methods #####
  def tableView(tableView, numberOfRowsInSection:section)

    if @engine.ipod.playlist
      @engine.ipod.playlist.items.size
    else
      0
    end

  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    @reuseIdentifier ||= "CELL_IDENTIFIER"

    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)

    if @engine.ipod.playlist
      song = @engine.ipod.playlist.items[indexPath.row]

      cell.textLabel.text = song.valueForProperty(MPMediaItemPropertyTitle)
      cell.detailTextLabel.text = song.valueForProperty(MPMediaItemPropertyArtist)
      cell.imageView.image = song.valueForProperty(MPMediaItemPropertyArtwork).imageWithSize(CGSizeMake(55, 55))
      cell.imageView.image ||= UIImage.imageNamed("albumartblank")

      # need to implement a better way of doing this that doesn't call updateTable every time a track changes???
      if song == @engine.ipod.nowPlayingItem
        # cell.textLabel.font = UIFont.boldSystemFontOfSize(cell.textLabel.font.pointSize)
        cell.textLabel.textColor = UIColor.colorWithHue(30/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
        # cell.detailTextLabel.font = UIFont.boldSystemFontOfSize(cell.detailTextLabel.font.pointSize)
        # cell.textLabel.textColor = UIColor.orangeColor
        cell.detailTextLabel.textColor = UIColor.colorWithHue(34/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
      end

      cell
    else
      nil
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    @engine.playiPodItem(indexPath.row)

    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end

  def scrollViewDidEndDecelerating(scrollView)

    @selectedSting = (scrollView.contentOffset.x / scrollView.frame.size.width).to_int
    @stingPage.currentPage = @selectedSting

  end
  
end