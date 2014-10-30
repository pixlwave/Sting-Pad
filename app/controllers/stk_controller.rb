class StkController < UIViewController
  extend IB

  outlet :playlistTable, UITableView
  outlet :ipodShuffleButton, UIButton
  outlet :ipodPlayButton, UIButton
  outlet :stingScrollView, UIScrollView
  outlet :stingPage, UIPageControl
  outlet :playingLabel, UILabel

  def viewDidLoad

    super

    # instantiate engine and make self delegate for sting players
    @engine = Engine.sharedClient
    @engine.setStingDelegates(self)

    # puts yellow view under status bar on iOS 7, handling Insets for correct scrolling
    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 && UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad
      @playlistTable.setContentInset(UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
      @playlistTable.setScrollIndicatorInsets(UIEdgeInsetsMake(UIApplication.sharedApplication.statusBarFrame.size.height, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
      @statusBarView = UIView.alloc.initWithFrame(UIApplication.sharedApplication.statusBarFrame)
      @statusBarView.backgroundColor = self.view.backgroundColor
      self.view.addSubview(@statusBarView)
    end

    # fonts for use throughout
    @titleFont = UIFont.fontWithName(@engine.fontName, size: 18)
    @subtitleFont = UIFont.fontWithName(@engine.fontName, size: 12)

    # control of the table
    @playlistTable.delegate = self
    @playlistTable.dataSource = self

    # make array to hold the sting views and get screen width for positioning
    @stingViews = Array.new(@engine.sting.count)
    screenWidth = UIScreen.mainScreen.bounds.size.width

    # add sting views to sting scroll view
    @stingViews.count.times do |i|
      v = StingView.alloc.initWithFrame(CGRectMake(i * screenWidth, 0, screenWidth, @stingScrollView.frame.size.height))
      v.playButton.when(UIControlEventTouchDown) { play }
      v.stopButton.when(UIControlEventTouchUpInside) { stop }
      v.titleLabel.font = @titleFont
      v.titleLabel.text = @engine.sting[i].title
      @stingViews[i] = v

      @stingScrollView.addSubview(@stingViews[i])
    end

    @playingLabel.font = UIFont.fontWithName(@engine.fontName, size: 11)

    # set up scroll view for playing stings
    @stingScrollView.setContentSize(CGSizeMake(@stingViews.last.frame.origin.x + @stingViews.last.frame.size.width, @stingViews.first.frame.size.height))
    @stingScrollView.delaysContentTouches = false           # prevents scroll view from momentarily blocking the play button's action
    @stingScrollView.delegate = self
    @selectedSting = 0

  end

  def viewWillAppear(animated)

    super

    # listen for iPod playback changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'updateTable', name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object:nil)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'playbackStateDidChange:', name:MPMusicPlayerControllerPlaybackStateDidChangeNotification, object:nil)

    # listen for iPod library changes
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'refreshPlaylists', name:MPMediaLibraryDidChangeNotification, object:nil)

    # update shuffle button in case changed outside of app
    @ipodShuffleButton.selected = @engine.ipod.shuffleState unless Device.simulator?   # TODO: observe this?

  end

  def viewDidAppear(animated)

    super

    showWalkthrough if (Turnkey.unarchive("walkthroughVersionSeen") || 0) < WalkthroughController.version

  end

  def viewWillDisappear(animated)

    super
  
    # remove all observers when view isn't visable (because someone said so)
    NSNotificationCenter.defaultCenter.removeObserver(self)
  
  end

  def play

    # plays selected sting (from sting scroll view) and shows that it's playing
    @engine.playSting(@selectedSting)
    @playingLabel.hidden = false

  end

  def stop

    # stops and hides the playing label
    @engine.stopSting
    @playingLabel.hidden = true

  end

  def iPodPlayPause

    # handle play/pause properly
    if @engine.ipod.isPlaying
      @engine.pauseiPod
    else
      @engine.playiPod
      @playingLabel.hidden = true   # remove sting playing label (should go in the engine probably)
    end

  end

  def iPodPrevious

    @engine.ipod.previous

  end

  def iPodNext

    @engine.ipod.next

  end

  def iPodShuffle

    shuffleState = @engine.ipod.toggleShuffle
    @ipodShuffleButton.selected = @engine.ipod.shuffleState

  end

  def updateStingTitles

    # get titles from stings
    @stingViews.each_with_index do |v, i|
      v.titleLabel.text = @engine.sting[i].title
    end

  end

  def refreshPlaylists

    @engine.ipod.refreshPlaylists
    updateTable

  end

  def updateTable

    @playlistTable.reloadData

  end

  def playbackStateDidChange(notification)

    updatePlayPause

    # correct (but buggy) alternative here:
    # http://stackoverflow.com/questions/1324409/mpmusicplayercontroller-stops-sending-notifications

  end

  def updatePlayPause

    @ipodPlayButton.selected = @engine.ipod.isPlaying

  end

  def playlistDidChange

    # called when ipod library changes
    updateTable

  end

  def showWalkthrough

    # instantiate walkthrough controller and present
    walksb = UIStoryboard.storyboardWithName("Walkthrough", bundle: nil)
    walkvc = walksb.instantiateViewControllerWithIdentifier("WalkthroughController")
    walkvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve
    presentViewController(walkvc, animated:true, completion:nil)
    
    # record the version being seen to allow ui updates to be shown in future versions
    Turnkey.archive(WalkthroughController.version, "walkthroughVersionSeen")

  end


  #### Segue methods ####
  def prepareForSegue(segue, sender:sender)

    if segue.identifier == "LoadSting"
      segue.destinationViewController.topViewController.stingIndex = @selectedSting
    end

  end


  #### Table View delegate methods ####
  def tableView(tableView, numberOfRowsInSection:section)

    if @engine.ipod.playlist
      @engine.ipod.playlist.items.size
    else
      0       # returned if the library/playist is non-existent
    end

  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    @reuseIdentifier ||= "CELL_IDENTIFIER"

    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)

    # ensure library/playlist contains songs
    if @engine.ipod.playlist
      
      # get request song
      song = @engine.ipod.playlist.items[indexPath.row]

      # format cell
      cell.textLabel.font = @titleFont
      cell.detailTextLabel.font = @subtitleFont

      # fill out cell as appropriate
      cell.textLabel.text = song.valueForProperty(MPMediaItemPropertyTitle)
      cell.detailTextLabel.text = song.valueForProperty(MPMediaItemPropertyArtist)

      if artwork = song.valueForProperty(MPMediaItemPropertyArtwork)      # iOS 8 returns nil if artwork is missing
        artwork = artwork.imageWithSize(CGSizeMake(55, 55))
      end

      cell.imageView.image = artwork || UIImage.imageNamed("albumartblank")   # fall back to blank artwork (iOS 6/7 might fail above test??)

      # need to implement a better way of doing this that doesn't call updateTable every time a track changes???
      # color the now playing song in orange (slightly darker than the main orange for balance)
      if song == @engine.ipod.nowPlayingItem
        cell.textLabel.textColor = UIColor.colorWithHue(30/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
        cell.detailTextLabel.textColor = UIColor.colorWithHue(34/360.0, saturation:1.0, brightness:0.95, alpha:1.0)
      else
        cell.textLabel.textColor = UIColor.darkTextColor
        cell.detailTextLabel.textColor = UIColor.darkTextColor
      end

      cell

    else
      nil   # returns nil if there isn't any items (probaly never reached as unlikely to be requested)
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    # play selected song
    @engine.playiPodItem(indexPath.row)

    # hides sting playing label
    # needs a more "universal" way of calling stop (move from engine to here?)
    @playingLabel.hidden = true

    # clear selection
    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end


  #### Scroll View delegate methods ####
  def scrollViewDidEndDecelerating(scrollView)

    # update selected sting when sting scroll view has completed animating
    if scrollView == @stingScrollView
      @selectedSting = (scrollView.contentOffset.x / scrollView.frame.size.width).to_int
      @stingPage.currentPage = @selectedSting
    end

  end
  
end