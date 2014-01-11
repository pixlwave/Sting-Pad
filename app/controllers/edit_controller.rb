class EditController < UIViewController
  extend IB

  include BW::KVO

  outlet :editScrollView, UIScrollView
  outlet :editView, UIView
  outlet :titleLabel0, UILabel
  outlet :artistLabel0, UILabel
  outlet :waveView0, UIView
  outlet :titleLabel1, UILabel
  outlet :artistLabel1, UILabel
  outlet :waveView1, UIView
  outlet :titleLabel2, UILabel
  outlet :artistLabel2, UILabel
  outlet :waveView2, UIView

  outlet :playlistPicker, UIPickerView

  def viewDidLoad

    @engine = Engine.sharedClient

    updateLabels

    waveFrame = @waveView0.frame
    @wave0 = FDWaveformView.alloc.initWithFrame(waveFrame)
    @wave0.doesAllowScrubbing = true
    @editView.addSubview(@wave0)
    updateWaveURL(0)

    observe(@wave0, "progressSamples") do |old_value, new_value|
      cue = new_value.to_f / @wave0.totalSamples
      @engine.sting[0].setCue(cue)
    end

    waveFrame = @waveView1.frame
    @wave1 = FDWaveformView.alloc.initWithFrame(waveFrame)
    @wave1.doesAllowScrubbing = true
    @editView.addSubview(@wave1)
    updateWaveURL(1)

    observe(@wave1, "progressSamples") do |old_value, new_value|
      cue = new_value.to_f / @wave1.totalSamples
      @engine.sting[1].setCue(cue)
    end

    waveFrame = @waveView2.frame
    @wave2 = FDWaveformView.alloc.initWithFrame(waveFrame)
    @wave2.doesAllowScrubbing = true
    @editView.addSubview(@wave2)
    updateWaveURL(2)

    observe(@wave2, "progressSamples") do |old_value, new_value|
      cue = new_value.to_f / @wave2.totalSamples
      @engine.sting[2].setCue(cue)
    end

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

  def updateLabels

    @titleLabel0.text = @engine.sting[0].title
    @artistLabel0.text = @engine.sting[0].artist

    @titleLabel1.text = @engine.sting[1].title
    @artistLabel1.text = @engine.sting[1].artist

    @titleLabel2.text = @engine.sting[2].title
    @artistLabel2.text = @engine.sting[2].artist

  end

  def updateWaveURL(player)

    case player
    when 0
      render = Dispatch::Queue.main
      render.async {
        @wave0.setAudioURL(@engine.sting[0].url)
        @wave0.setProgressSamples(@wave0.totalSamples * @engine.sting[0].getCue)
      }
    when 1
      render = Dispatch::Queue.main
      render.async {
        @wave1.setAudioURL(@engine.sting[1].url)
        @wave1.setProgressSamples(@wave1.totalSamples * @engine.sting[1].getCue)
      }
    when 2
      render = Dispatch::Queue.main
      render.async {
        @wave2.setAudioURL(@engine.sting[2].url)
        @wave2.setProgressSamples(@wave2.totalSamples * @engine.sting[2].getCue)
      }
    end

  end


  ##### Media picker delegate methods #####
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    track = mediaItemCollection.items[0]
    @engine.sting[@loadingTrack].loadSting(mediaItemCollection.items[0])
    updateLabels
    updateWaveURL(@loadingTrack)

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