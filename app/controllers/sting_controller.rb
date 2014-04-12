class StingController < UIViewController
  extend IB

  # observing for waveform view progress changes
  include BW::KVO

  attr_accessor :stingIndex

  outlet :editView, UIView
  outlet :stingNumberLabel, UILabel
  outlet :titleLabel, UILabel
  outlet :artistLabel, UILabel
  outlet :waveLoadImageView, UIImageView

  def viewDidLoad

    # access the music
    @engine = Engine.sharedClient

    # match titlebar colour to main controller - is this needed: a colour bug??
    self.view.backgroundColor = self.presentingViewController.view.backgroundColor

    # load track info
    @stingNumberLabel.text = "Sting #{@stingIndex+1}"
    updateLabels

    # get waveform view positions
    waveFrame = @waveLoadImageView.frame

    # not using whilst storing waveformView inside Sting object
    # @wave = FDWaveformView.alloc.initWithFrame(waveFrame)
    # @wave.doesAllowScrubbing = true
    # @wave.delegate = self
    # @editView.addSubview(@wave)
    # updateWaveURL()

    # temporary bodge to stop waveform being rendered each time it is presented
    # memory usage is probably excessive!
    @wave = @engine.sting[@stingIndex].waveform
    @wave.setFrame(waveFrame) unless @engine.wavesLoaded[@stingIndex]
    @wave.delegate = self
    @editView.addSubview(@wave)

    # update cue point when waveform view touched and save
    observe(@wave, "progressSamples") do |old_value, new_value|
      cue = new_value.to_f / @wave.totalSamples
      @engine.sting[@stingIndex].setCue(cue)
      Turnkey.archive(@engine.sting[@stingIndex].cuePoint, "Sting #{@stingIndex} Cue Point")
    end

    # temporary bodge to remove waveform loading image if the waveform isn't going to render
    if @engine.wavesLoaded[@stingIndex]
      waveLoadImageView.removeFromSuperview
    else
      # otherwise they will have loaded so save for next time
      @engine.wavesLoaded[@stingIndex] = true
    end

    # refresh playlists in case anything has changed
    @engine.ipod.refreshPlaylists

  end

  def dismiss

    # display updates before dismissing
    self.presentingViewController.updateStingTitles
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def loadTrack

    # present music picker to load a track from ipod
    mediaPicker = MPMediaPickerController.alloc.initWithMediaTypes(MPMediaTypeMusic)
    mediaPicker.delegate = self
    mediaPicker.showsCloudItems = false  # hides iTunes in the Cloud items, which crash the app if picked
    mediaPicker.allowsPickingMultipleItems = false
    self.presentModalViewController(mediaPicker, animated:true)

  end

  def updateLabels

    # get all the relevant track info from the engine
    @titleLabel.text = @engine.sting[@stingIndex].title
    @artistLabel.text = @engine.sting[@stingIndex].artist

  end

  def updateWaveURL

    @wave.setAudioURL(@engine.sting[@stingIndex].url)
    @wave.setProgressSamples(@wave.totalSamples * @engine.sting[@stingIndex].getCue)

  end


  ##### Waveform view delegate methods #####
  def waveformViewDidRender(waveformView)

    waveLoadImageView.removeFromSuperview

  end


  ##### Media picker delegate methods #####
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    # load media item into the currently loading sting player and update labels
    track = mediaItemCollection.items[0]    # not needed...
    @engine.sting[@stingIndex].loadSting(mediaItemCollection.items[0])
    updateLabels

    # add wave loading image whilst waveform generates
    @editView.addSubview(waveLoadImageView)

    # generate new waveform
    updateWaveURL

    # dismiss media picker
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def mediaPickerDidCancel(mediaPicker)

    # dismiss media picker
    self.dismissViewControllerAnimated(true, completion:nil)

  end

end