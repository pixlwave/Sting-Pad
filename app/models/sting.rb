class Sting

  attr_reader :url, :title, :artist, :cuePoint

  def initialize(url, title, artist, cuePoint)

    # TODO: use error handler rather than check for nil AVAudioPlayer
    @url = url
    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)

    if @stingPlayer
      @title = title
      @artist = artist
      @cuePoint = cuePoint
    else
      @url = NSURL.fileURLWithPath(NSBundle.mainBundle.pathForResource("ComputerMagic", ofType:"m4a"))
      @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)
      @title = "No Sting Loaded"
      @artist = "No Artist"
      @cuePoint = 0
    end

    @stingPlayer.delegate = self
    @stingPlayer.prepareToPlay
    @stingPlayer.numberOfLoops = 0
    @stingPlayer.currentTime = @cuePoint

  end

  def play

    @stingPlayer.play

  end

  def stop

    @stingPlayer.stop
    @stingPlayer.currentTime = @cuePoint

  end

  def loadSting(mediaItem)

    # init player with new track and set cue to 0
    @url = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL)
    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)
    @cuePoint = 0

    @title = mediaItem.valueForProperty(MPMediaItemPropertyTitle)
    @artist = mediaItem.valueForProperty(MPMediaItemPropertyArtist)

    Engine.saveState

  end

  def setCue(cuePoint)

    @cuePoint = cuePoint * @stingPlayer.duration
    @stingPlayer.currentTime = @cuePoint
    Engine.saveState

  end

  def getCue

    @cuePoint / @stingPlayer.duration

  end

end