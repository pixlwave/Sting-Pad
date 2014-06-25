class Sting

  attr_accessor :delegate
  attr_reader :url, :title, :artist, :cuePoint, :waveform

  def initialize(url, title, artist, cuePoint)

    # TODO: use error handler rather than check for nil AVAudioPlayer
    @url = url
    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)

    # checks if player loaded, as an old url will return a nil object
    if @stingPlayer
      @title = title
      @artist = artist
      @cuePoint = cuePoint
    else
      @url = NSURL.fileURLWithPath(NSBundle.mainBundle.pathForResource("ComputerMagic", ofType:"m4a"))
      @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)
      @title = "Chime"
      @artist = "Default Sting"
      @cuePoint = 0
    end

    @stingPlayer.delegate = self
    @stingPlayer.numberOfLoops = 0  # needed?
    @stingPlayer.currentTime = @cuePoint
    @stingPlayer.prepareToPlay

    @waveform = FDWaveformView.alloc.initWithFrame(CGRectZero)
    @waveform.audioURL = @url
    @waveform.doesAllowScrubbing = true
    # @waveform.doesAllowStretchAndScroll = true
    @waveform.wavesColor = UIColor.blueColor
    @waveform.progressColor = UIColor.whiteColor
    @waveform.setProgressSamples(waveform.totalSamples * getCue)

  end

  def play

    @stingPlayer.play

  end

  def stop

    @stingPlayer.stop
    @stingPlayer.currentTime = @cuePoint
    @stingPlayer.prepareToPlay

  end

  def loadSting(mediaItem)

    # init player with new track and set cue to 0
    @url = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL)

    @stingPlayer = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)
    @stingPlayer.delegate = self    # new object still needs to call delegate methods
    @stingPlayer.numberOfLoops = 0  # needed?

    @cuePoint = 0
    @stingPlayer.currentTime = @cuePoint
    @stingPlayer.prepareToPlay

    @title = mediaItem.valueForProperty(MPMediaItemPropertyTitle)
    @artist = mediaItem.valueForProperty(MPMediaItemPropertyArtist)

    Engine.saveState

  end

  def setCue(cuePoint)

    @cuePoint = cuePoint * @stingPlayer.duration
    @stingPlayer.currentTime = @cuePoint
    @stingPlayer.prepareToPlay

  end

  def getCue

    @cuePoint / @stingPlayer.duration

  end


  #### Delegate Methods ####

  def audioPlayerDidFinishPlaying(player, successfully:flag)

    # Is this the correct way to do delegates? delegate.stingFinished(self)
    # delegate.stingDidStop(self) -> label.hidden
    # then call currentTime=cuePoint from here
    delegate.stop

  end

  def audioPlayerBeginInterruption(player)

    delegate.stop

  end

end