class EditController < UIViewController
  extend IB

  outlet :cuePoint, UISlider
  outlet :titleLabel, UILabel
  outlet :artistLabel, UILabel
  outlet :waveView, UIView
  outlet :playlistPicker, UIPickerView

  def viewDidLoad

    @engine = Engine.sharedClient

    titleLabel.text = @engine.sting.title
    artistLabel.text = @engine.sting.artist

    cuePoint.value = @engine.sting.getCue
    cuePoint.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      waveFrame = @waveView.frame
      @wave = FDWaveformView.alloc.initWithFrame(waveFrame)
      # @wave.doesAllowScrubbing = true
      self.view.addSubview(@wave)
      updateWaveURL
    end

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

  def setCue

    @engine.sting.setCue(cuePoint.value)
    updateWaveCue

  end

  def updateWaveURL

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      render = Dispatch::Queue.main
      render.async {
        @wave.setAudioURL(@engine.sting.url)
        updateWaveCue
      }
    end

  end

  def updateWaveCue

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      @wave.setProgressSamples(@wave.totalSamples * cuePoint.value)
    end

  end


  # Media picker delegate methods
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    track = mediaItemCollection.items[0]
    @engine.sting.loadSting(mediaItemCollection.items[0])
    titleLabel.text = @engine.sting.title
    artistLabel.text = @engine.sting.artist
    cuePoint.value = 0
    updateWaveURL

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def mediaPickerDidCancel(mediaPicker)

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  # PickerView delegate methods
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