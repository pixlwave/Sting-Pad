class EditController < UIViewController
  extend IB

  outlet :cuePoint, UISlider
  outlet :titleLabel, UILabel
  outlet :artistLabel, UILabel
  outlet :waveView, UIView
  outlet :playlistPicker, UIPickerView

  def viewDidLoad

    titleLabel.text = Sting::Player.title
    artistLabel.text = Sting::Player.artist

    cuePoint.value = Sting::Player.getCue
    cuePoint.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      waveFrame = @waveView.frame
      @wave = FDWaveformView.alloc.initWithFrame(waveFrame)
      self.view.addSubview(@wave)
      updateWaveURL
    end

    playlistPicker.delegate = self
    playlistPicker.dataSource = self
    playlistPicker.selectRow(Music::Player.selectedPlaylist, inComponent:0, animated:true)

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

    Sting::Player.setCue(cuePoint.value)
    updateWaveCue

  end

  def updateWaveURL

    if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1
      render = Dispatch::Queue.main
      render.async {
        @wave.setAudioURL(Sting::Player.url)
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
    Sting::Player.loadSting(mediaItemCollection.items[0])
    titleLabel.text = Sting::Player.title
    artistLabel.text = Sting::Player.artist
    cuePoint.value = 0
    updateWaveURL

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def mediaPickerDidCancel(mediaPicker)

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def numberOfComponentsInPickerView(pickerView)

    1

  end

  def pickerView(pickerView, numberOfRowsInComponent:component)

    Music::Player.allPlaylists.size

  end

  def pickerView(pickerView, titleForRow:row, forComponent:component)

    Music::Player.allPlaylists[row].valueForProperty(MPMediaPlaylistPropertyName)

  end

  def pickerView(pickerView, didSelectRow:row, inComponent:component)

    Music::Player.usePlaylist(row)
    self.presentingViewController.updateTable

  end

end