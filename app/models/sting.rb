class Sting

  attr_reader :title, :artist

  def initialize

    @file = NSBundle.mainBundle.pathForResource("ComputerMagic", ofType:"m4a")
    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(NSURL.fileURLWithPath(@file), error:nil)
    @stingPlayer.delegate = self
    @stingPlayer.prepareToPlay
    @stingPlayer.numberOfLoops = 0

    @cuePoint = 0

    @title = "Empty"
    @artist = "Empty"

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

  end

  def setCue(cuePoint)

    @cuePoint = cuePoint * @stingPlayer.duration
    @stingPlayer.currentTime = @cuePoint

  end

  def getCue

    @cuePoint / @stingPlayer.duration

  end

  Player = Sting.new

  def archive

    Turnkey.archive(@stingPlayer, "Sting Player")
    Turnkey.archive(@cuePoint, "Cue Point")
    Turnkey.archive(@title, "Sting Title")
    Turnkey.archive(@artist, "Sting Artist")

  end

  def unarchive

    @stingPlayer = Turnkey.unarchive("Sting Player")
    @cuePoint = Turnkey.unarchive("Cue Point")
    @title = Turnkey.unarchive("Sting Title")
    @artist = Turnkey.unarchive("Sting Artist")

  end

end