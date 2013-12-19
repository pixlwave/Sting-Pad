class StkController < UIViewController
  extend IB

  outlet :titleLabel, UILabel
  outlet :playlistTable, UITableView
  outlet :stingScrollView, UIScrollView

  def viewDidLoad

    # if Music::Player.playbackState == MPMusicPlaybackStatePlaying
    #   playlistTable.enabled = false
    #   @iPodLabel = UILabel.alloc.initWithFrame(CGRectZero)
    #   @iPodLabel.text = "Music Playing from iPod"
    #   @iPodLabel.sizeToFit
    #   @iPodLabel.center = @playlistTable.center
    #   self.addSubview(@iPodLabel)
    # else
      # @playlistMediaItems = Music.getPlaylist
    # end

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      @playlistTable.setContentInset(UIEdgeInsetsMake(20, @playlistTable.contentInset.left, @playlistTable.contentInset.bottom, @playlistTable.contentInset.right))
      @statusBarView = UIView.alloc.initWithFrame(UIApplication.sharedApplication.statusBarFrame)
      @statusBarView.backgroundColor = self.view.backgroundColor
      self.view.addSubview(@statusBarView)
    end

    @playlistTable.delegate = self
    @playlistTable.dataSource = self

    @stingScrollView.setContentSize(CGSizeMake(324, 64))
    @stingScrollView.delegate = self
    @selectedSting = 0

    updateTitle

  end

  def play

    Sting::Player.play

  end

  def stop

    Sting::Player.stop

  end

  def iPodPlay

    Music::Player.play

  end

  def iPodPause

    Music::Player.pause

  end

  def iPodPrevious

    Music::Player.Previous

  end

  def iPodNext

    Music::Player.Next

  end

  def updateTitle

    @titleLabel.text = Sting::Player.title

  end

  def updateTable

    @playlistTable.reloadData

  end

  def tableView(tableView, numberOfRowsInSection:section)

    if Music::Player.playlist
      Music::Player.playlist.items.size
    else
      0
    end

  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    @reuseIdentifier ||= "CELL_IDENTIFIER"

    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)

    if Music::Player.playlist
      song = Music::Player.playlist.items[indexPath.row]

      cell.textLabel.text = song.valueForProperty(MPMediaItemPropertyTitle)
      cell.detailTextLabel.text = song.valueForProperty(MPMediaItemPropertyArtist)
      cell.imageView.image = song.valueForProperty(MPMediaItemPropertyArtwork).imageWithSize(CGSizeMake(55, 55))
      cell.imageView.image ||= UIImage.imageNamed("albumartblank")
      cell
    else
      nil
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    Music::Player.playItem(indexPath.row)

    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end

  def scrollViewDidEndDecelerating(scrollView)

    @selectedSting = (scrollView.contentOffset.x / scrollView.frame.size.width).to_int
    puts "Page #{@selectedSting}"

  end
  
end