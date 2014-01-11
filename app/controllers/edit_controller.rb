class EditController < UIViewController
  extend IB

  outlet :editScrollView, UIScrollView
  outlet :editView, UIView
  outlet :titleLabel0, UILabel
  outlet :artistLabel0, UILabel
  outlet :cuePoint0, UISlider
  outlet :waveView0, UIView
  outlet :titleLabel1, UILabel
  outlet :artistLabel1, UILabel
  outlet :cuePoint1, UISlider
  outlet :waveView1, UIView
  outlet :titleLabel2, UILabel
  outlet :artistLabel2, UILabel
  outlet :cuePoint2, UISlider
  outlet :waveView2, UIView

  outlet :playlistPicker, UIPickerView

  def viewDidLoad

    @engine = Engine.sharedClient

    updateLabels
    @cuePoint0.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)
    @cuePoint1.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)
    @cuePoint2.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)

    waveFrame = @waveView0.frame
    @wave = FDWaveformView.alloc.initWithFrame(waveFrame)
    # @wave.doesAllowScrubbing = true
    @editView.addSubview(@wave)
    updateWaveURL

    @editScrollView.setContentSize(@editView.frame.size)
    @editScrollView.delegate = self

    playlistPicker.delegate = self
    playlistPicker.dataSource = self
    playlistPicker.selectRow(@engine.ipod.selectedPlaylist, inComponent:0, animated:true)

  end

  def dismiss

    self.presentingViewController.updateTitle
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def loadTrack

    mediaPicker = MPMediaPickerController.alloc.initWithMediaTypes(MPMediaTypeMusic)
    mediaPicker.delegate = self
    mediaPicker.allowsPickingMultipleItems = false
    self.presentModalViewController(mediaPicker, animated:true)

  end

  def loadTrack0

    @loadingTrack = 0
    loadTrack

  end

  def loadTrack1

    @loadingTrack = 1
    loadTrack

  end

  def loadTrack2

    @loadingTrack = 2
    loadTrack

  end

  def setCue

    @engine.sting[0].setCue(cuePoint0.value)
    updateWaveCue

  end

  def updateLabels

    @titleLabel0.text = @engine.sting[0].title
    @artistLabel0.text = @engine.sting[0].artist
    @cuePoint0.value = @engine.sting[0].getCue

    @titleLabel1.text = @engine.sting[1].title
    @artistLabel1.text = @engine.sting[1].artist
    @cuePoint1.value = @engine.sting[1].getCue

    @titleLabel2.text = @engine.sting[2].title
    @artistLabel2.text = @engine.sting[2].artist
    @cuePoint2.value = @engine.sting[2].getCue

  end

  def updateWaveURL

    render = Dispatch::Queue.main
    render.async {
      @wave.setAudioURL(@engine.sting[0].url)
      updateWaveCue
    }

  end

  def updateWaveCue

    @wave.setProgressSamples(@wave.totalSamples * cuePoint0.value)

  end


  ##### Media picker delegate methods #####
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    track = mediaItemCollection.items[0]
    @engine.sting[@loadingTrack].loadSting(mediaItemCollection.items[0])
    updateLabels
    updateWaveURL

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def mediaPickerDidCancel(mediaPicker)

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  ##### PickerView delegate methods #####
  def numberOfComponentsInPickerView(pickerView)

    1

  end

  def pickerView(pickerView, numberOfRowsInComponent:component)

    @engine.ipod.allPlaylists.size

  end

  def pickerView(pickerView, titleForRow:row, forComponent:component)

    @engine.ipod.allPlaylists[row].valueForProperty(MPMediaPlaylistPropertyName)

  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)

    @engine.ipod.usePlaylist(row)
    self.presentingViewController.updateTable

  end

end