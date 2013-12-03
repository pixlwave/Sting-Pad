class Sting

  attr_reader :url, :title, :artist

  def initialize

    # TODO: use error handler rather than check for nil AVAudioPlayer
    @url = Turnkey.unarchive("Sting URL")
    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)

    if @stingPlayer
      @title = Turnkey.unarchive("Sting Title") || "No Sting Loaded"
      @artist = Turnkey.unarchive("Sting Artist") || "No Artist"
      @cuePoint = Turnkey.unarchive("Cue Point") || 0
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

    Music::Player.pause
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

    saveState

  end

  def setCue(cuePoint)

    @cuePoint = cuePoint * @stingPlayer.duration
    @stingPlayer.currentTime = @cuePoint
    saveState

  end

  def getCue

    @cuePoint / @stingPlayer.duration

  end

  Player = Sting.new

  def saveState

    Turnkey.archive(@url, "Sting URL")
    Turnkey.archive(@cuePoint, "Cue Point")
    Turnkey.archive(@title, "Sting Title")
    Turnkey.archive(@artist, "Sting Artist")

  end

end