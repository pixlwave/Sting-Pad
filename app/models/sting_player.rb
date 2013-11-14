class StingPlayer

  def initialize

    # play even whilst muted - move to app didfinishlaunching
    AVAudioSession.sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error:nil)

    # allow mixing - move to app didfinishlaunching
    allowMixing = Pointer.new(:long)
    allowMixing[0] = true
    AudioSessionSetProperty(KAudioSessionProperty_OverrideCategoryMixWithOthers, 4, allowMixing)

    @file = NSBundle.mainBundle.pathForResource("ComputerMagic", ofType:"m4a")
    @player = AVAudioPlayer.alloc.initWithContentsOfURL(NSURL.fileURLWithPath(@file), error:nil)
    @player.delegate = self
    @player.prepareToPlay
    @player.numberOfLoops = 0

    @cuePoint = 0

  end

  def play

    @player.play

  end

  def stop

    @player.stop
    @player.currentTime = @cuePoint

  end

  def loadSting(mediaItem)

    @url = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL)
    @player = AVAudioPlayer.alloc.initWithContentsOfURL(@url, error:nil)
    @cuePoint = 0

  end

  def setCue(cuePoint)

    @cuePoint = cuePoint * @player.duration
    @player.currentTime = @cuePoint

  end

  def getCue

    @cuePoint / @player.duration

  end

end