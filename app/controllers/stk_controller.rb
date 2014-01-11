class StkController < UIViewController
  extend IB

  outlet :titleLabel0, UILabel
  outlet :titleLabel1, UILabel
  outlet :titleLabel2, UILabel
  outlet :playlistTable, UITableView
  outlet :stingScrollView, UIScrollView
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

    @stingScrollView.setContentSize(CGSizeMake(324, 64))
    @stingScrollView.delegate = self
    @selectedSting = 0

    updateTitle

  end

  def play

    # @engine.playSting
    @engine.playSting(@selectedSting)

  end

  def stop

    @engine.stopSting

  end

  def iPodPlay

    @engine.playiPod

  end

  def iPodPause

    @engine.pauseiPod

  end

  def iPodPrevious

    @engine.ipod.Previous

  end

  def iPodNext

    @engine.ipod.Next

  end

  def updateTitle

    @titleLabel0.text = @engine.sting[0].title
    @titleLabel1.text = @engine.sting[1].title
    @titleLabel2.text = @engine.sting[2].title

  end

  def updateTable

    @playlistTable.reloadData

  end

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
      cell
    else
      nil
    end

  end

  def tableView(tableView, didSelectRowAtIndexPath:indexPath)

    @engine.ipod.playItem(indexPath.row)

    tableView.deselectRowAtIndexPath(indexPath, animated:true)

  end

  def scrollViewDidEndDecelerating(scrollView)

    @selectedSting = (scrollView.contentOffset.x / scrollView.frame.size.width).to_int
    @stingPage.currentPage = @selectedSting
    puts "Page #{@selectedSting}"

  end
  
end