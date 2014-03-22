class StkController < UIViewController
  extend IB

  outlet :titleLabel0, UILabel
  outlet :titleLabel1, UILabel
  outlet :titleLabel2, UILabel
  outlet :titleLabel3, UILabel
  outlet :titleLabel4, UILabel
  outlet :playlistTable, UITableView
  outlet :ipodPlayButton, UIButton
  outlet :stingScrollView, UIScrollView
  outlet :stingView, UIView
  outlet :stingPage, UIPageControl
  outlet :playingLabel, UILabel

  def viewDidLoad

    @engine = Engine.sharedClient
    @engine.setStingDelegates(self)

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad
      @playlistTable.setContentInset(UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
      @playlistTable.setScrollIndicatorInsets(UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
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

    @ipodPlayImage = UIImage.imageNamed("ipodplay")
    @ipodPauseImage = UIImage.imageNamed("ipodpause")

  end

  def viewWillAppear(animated)

    # @ipodObserver = App.notification_center.observe MPMusicPlayerControllerNowPlayingItemDidChangeNotification do |notification|
    #   self.performSelector(updateTable, withObject:self, afterDelay:1)
    #   App.alert("Notified")
    # end

    NSNotificationCenter.defaultCenter.addObserver(self, selector:'updateTable', name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object:nil)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'playbackStateDidChange:', name:MPMusicPlayerControllerPlaybackStateDidChangeNotification, object:nil)

    NSNotificationCenter.defaultCenter.addObserver(self, selector:'refreshPlaylists', name:MPMediaLibraryDidChangeNotification, object:nil)

  end

  def viewDidAppear(animated)

    showWalkthrough if (Turnkey.unarchive("walkthroughVersionSeen") || 0) < WalkthroughController.version

  end

  def viewWillDisappear(animated)
  
    NSNotificationCenter.defaultCenter.removeObserver(self)
  
  end

  def play

    @engine.playSting(@selectedSting)
    @playingLabel.hidden = false

  end

  def stop

    @engine.stopSting
    @playingLabel.hidden = true

  end

  def iPodPlayPause

    if @engine.ipod.isPlaying
      @engine.pauseiPod
    else
      @engine.playiPod
      @playingLabel.hidden = true
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
    @titleLabel3.text = @engine.sting[3].title
    @titleLabel4.text = @engine.sting[4].title

  end

  def refreshPlaylists

    @engine.ipod.refreshPlaylists
    updateTable

  end

  def updateTable

    @playlistTable.reloadData

  end

  def playbackStateDidChange(notification)

    # http://stackoverflow.com/questions/1324409/mpmusicplayercontroller-stops-sending-notifications

    # state = notification.userInfo.objectForKey("MPMusicPlayerControllerPlaybackStateKey")

    # if state == MPMusicPlaybackStatePlaying
    #   @ipodPlayButton.setImage(@ipodPauseImage, forState:UIControlStateNormal)
    # else
    #   @ipodPlayButton.setImage(@ipodPlayImage, forState:UIControlStateNormal)
    # end

    updatePlayPause

  end

  def updatePlayPause

    if @engine.ipod.isPlaying
      @ipodPlayButton.setImage(@ipodPauseImage, forState:UIControlStateNormal)
    else
      @ipodPlayButton.setImage(@ipodPlayImage, forState:UIControlStateNormal)
    end

  end

  def playlistDidChange

    updateTable

  end

  def showWalkthrough

    walkvc = storyboard.instantiateViewControllerWithIdentifier("WalkthroughController")
    walkvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve
    presentViewController(walkvc, animated:true, completion:nil)
    Turnkey.archive(WalkthroughController.version, "walkthroughVersionSeen")

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
    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)

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
      else
        cell.textLabel.textColor = UIColor.darkTextColor
        cell.detailTextLabel.textColor = UIColor.darkTextColor
      end

      cell
    else
      nil
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    @engine.playiPodItem(indexPath.row)

    # needs a more "universal" way of calling stop (move from engine to here?)
    @playingLabel.hidden = true

    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end


  #### Scroll View delegate methods
  def scrollViewDidEndDecelerating(scrollView)

    if scrollView == @stingScrollView
      @selectedSting = (scrollView.contentOffset.x / scrollView.frame.size.width).to_int
      @stingPage.currentPage = @selectedSting
    end

  end
  
end