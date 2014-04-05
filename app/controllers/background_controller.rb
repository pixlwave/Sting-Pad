class BackgroundController < UITableViewController
  extend IB

  def viewDidLoad

    @engine = Engine.sharedClient

    @selectedPlaylist = @engine.ipod.selectedPlaylist

  end

  def viewWillAppear(animated)

    indexPath = NSIndexPath.indexPathForRow(@selectedPlaylist, inSection:0)         
    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPositionNone, animated:false)

  end

  def dismiss

    self.dismissViewControllerAnimated(true, completion:nil)

  end


  #### Table View Delegate Methods ####

  def tableView(tableView, numberOfRowsInSection:section)

    @engine.ipod.allPlaylists.size

  end

  def tableView(tableView, titleForHeaderInSection:section)

    "Playlists"

  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)

    @reuseIdentifier ||= "CELL_IDENTIFIER"

    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)
    cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: @reuseIdentifier)
    
    playlist = @engine.ipod.allPlaylists[indexPath.row]
    cell.textLabel.text = playlist.valueForProperty(MPMediaPlaylistPropertyName)

    if playlist == @engine.ipod.playlist
      cell.accessoryType = UITableViewCellAccessoryCheckmark
    else
      cell.accessoryType = UITableViewCellAccessoryNone
    end

    cell

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    # don't update playlist when it's already the current playlist
    unless indexPath.row == @selectedPlaylist
      @engine.ipod.usePlaylist(indexPath.row)
      self.presentingViewController.playlistDidChange

      # update checkmark and clear selection
      indexPaths = [NSIndexPath.indexPathForRow(@selectedPlaylist, inSection:0), indexPath]
      tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation:UITableViewRowAnimationAutomatic)

      @selectedPlaylist = @engine.ipod.selectedPlaylist
    end

    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end

end