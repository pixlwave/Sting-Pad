class StkController < UIViewController
  extend IB

  outlet :titleLabel, UILabel
  outlet :playlistTable, UITableView

  def viewDidLoad

    @stingPlayer = StingPlayer.new
    @iPodPlayer = MPMusicPlayerController.iPodMusicPlayer

    # if @iPodPlayer.playbackState == MPMusicPlaybackStatePlaying
    #   playlistTable.enabled = false
    #   @iPodLabel = UILabel.alloc.initWithFrame(CGRectZero)
    #   @iPodLabel.text = "Music Playing from iPod"
    #   @iPodLabel.sizeToFit
    #   @iPodLabel.center = @playlistTable.center
    #   self.addSubview(@iPodLabel)
    # else
      @playlistMediaItems = getPlaylist
    # end

    playlistTable.delegate = self
    playlistTable.dataSource = self

  end

  def play

    @iPodPlayer.pause
    @stingPlayer.play

  end

  def stop

    @stingPlayer.stop

  end

  def loadSting(mediaItem)

    @stingPlayer.loadSting(mediaItem)
    titleLabel.text = mediaItem.valueForProperty(MPMediaItemPropertyTitle)

  end

  def setCue(cuePoint)

    @stingPlayer.setCue(cuePoint)

  end

  def getCue

    @stingPlayer.getCue

  end

  def iPodPlay

    @stingPlayer.stop
    @iPodPlayer.play

  end

  def iPodPause

    @iPodPlayer.pause

  end

  def iPodPrevious

    @iPodPlayer.skipToPreviousItem

  end

  def iPodNext

    @iPodPlayer.skipToNextItem

  end

  def getPlaylist

    aList = nil

    playlistsQuery = MPMediaQuery.playlistsQuery
    playlistsArray = playlistsQuery.collections
    playlistsArray.each do |playlist|
      if playlist.valueForProperty(MPMediaPlaylistPropertyName) == "A-List"
        aList = playlist
      end
    end

    aList

  end

  def tableView(tableView, numberOfRowsInSection:section)

    if @playlistMediaItems
      @playlistMediaItems.items.size
    else
      0
    end

  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    @reuseIdentifier ||= "CELL_IDENTIFIER"

    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)

    if @playlistMediaItems
      song = @playlistMediaItems.items[indexPath.row]

      cell.textLabel.text = song.valueForProperty(MPMediaItemPropertyTitle)
      cell.detailTextLabel.text = song.valueForProperty(MPMediaItemPropertyArtist)
      cell.imageView.image = song.valueForProperty(MPMediaItemPropertyArtwork).imageWithSize(CGSizeMake(55, 55))
      cell
    else
      nil
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    # play item

  end
  
end