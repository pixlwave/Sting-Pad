class EditController < UIViewController
  extend IB

  include BW::KVO

  outlet :editScrollView, UIScrollView
  outlet :editView, UIView
  outlet :titleLabel0, UILabel
  outlet :artistLabel0, UILabel
  outlet :waveLoadImageView0, UIImageView
  outlet :titleLabel1, UILabel
  outlet :artistLabel1, UILabel
  outlet :waveLoadImageView1, UIImageView
  outlet :titleLabel2, UILabel
  outlet :artistLabel2, UILabel
  outlet :waveLoadImageView2, UIImageView
  outlet :titleLabel3, UILabel
  outlet :artistLabel3, UILabel
  outlet :waveLoadImageView3, UIImageView
  outlet :titleLabel4, UILabel
  outlet :artistLabel4, UILabel
  outlet :waveLoadImageView4, UIImageView

  outlet :playlistPicker, UIPickerView

  def viewDidLoad

    @engine = Engine.sharedClient

    updateLabels

    waveFrame = Array.new(@engine.sting.size)
    waveFrame[0] = @waveLoadImageView0.frame
    waveFrame[1] = @waveLoadImageView1.frame
    waveFrame[2] = @waveLoadImageView2.frame
    waveFrame[3] = @waveLoadImageView3.frame
    waveFrame[4] = @waveLoadImageView4.frame
    
    @wave = Array.new(waveFrame.size)
    @wave.each_with_index do |w, i|

      # not using whilst storing waveformView inside Sting object
      # @wave[i] = FDWaveformView.alloc.initWithFrame(waveFrame[i])
      # @wave[i].doesAllowScrubbing = true
      # @wave[i].delegate = self
      # @editView.addSubview(@wave[i])
      # updateWaveURL(i)

      # temporary bodge to stop waveform being rendered each time it is presented
      # memory usage is probably excessive!
      @wave[i] = @engine.sting[i].waveform
      @wave[i].setFrame(waveFrame[i]) unless @engine.wavesLoaded
      @wave[i].delegate = self
      @editView.addSubview(@wave[i])

      observe(@wave[i], "progressSamples") do |old_value, new_value|
        cue = new_value.to_f / @wave[i].totalSamples
        @engine.sting[i].setCue(cue)
        Turnkey.archive(@engine.sting[i].cuePoint, "Cue Point #{i}")
      end
    end

    # temporary bodge to remove waveform loading image if the waveform isn't going to render
    if @engine.wavesLoaded
      waveLoadImageView0.removeFromSuperview
      waveLoadImageView1.removeFromSuperview
      waveLoadImageView2.removeFromSuperview
      waveLoadImageView3.removeFromSuperview
      waveLoadImageView4.removeFromSuperview
    else
      @engine.wavesLoaded = true
    end

    @editScrollView.setContentSize(@editView.frame.size)
    @editScrollView.delegate = self

    # refresh playlists in case anything has changed
    @engine.ipod.refreshPlaylists

    playlistPicker.delegate = self
    playlistPicker.dataSource = self

    # searches for active playlist in playlists array and uses this to select it in the picker
    playlistIndex = @engine.ipod.allPlaylists.index(@engine.ipod.playlist)
    playlistPicker.selectRow(playlistIndex || 0, inComponent:0, animated:true)

  end

  def dismiss

    self.presentingViewController.updateStingTitles
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def loadTrack

    mediaPicker = MPMediaPickerController.alloc.initWithMediaTypes(MPMediaTypeMusic)
    mediaPicker.delegate = self
    mediaPicker.showsCloudItems = false  # hides iTunes in the Cloud items, which crash the app if picked
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

  def loadTrack3

    @loadingTrack = 3
    loadTrack

  end

    def loadTrack4

    @loadingTrack = 4
    loadTrack

  end

  def updateLabels

    @titleLabel0.text = @engine.sting[0].title
    @artistLabel0.text = @engine.sting[0].artist

    @titleLabel1.text = @engine.sting[1].title
    @artistLabel1.text = @engine.sting[1].artist

    @titleLabel2.text = @engine.sting[2].title
    @artistLabel2.text = @engine.sting[2].artist

    @titleLabel3.text = @engine.sting[3].title
    @artistLabel3.text = @engine.sting[3].artist

    @titleLabel4.text = @engine.sting[4].title
    @artistLabel4.text = @engine.sting[4].artist

  end

  def updateWaveURL(i)

    @wave[i].setAudioURL(@engine.sting[i].url)
    @wave[i].setProgressSamples(@wave[i].totalSamples * @engine.sting[i].getCue)

  end


  ##### Waveform view delegate methods #####
  def waveformViewDidRender(waveformView)

    # fix this crappy bodge!!!
    num = nil

    @wave.each_with_index do |w, i|
      num = i if waveformView == w
    end

    if num == 0
      waveLoadImageView0.removeFromSuperview
    elsif num == 1
      waveLoadImageView1.removeFromSuperview
    elsif num == 2
      waveLoadImageView2.removeFromSuperview
    elsif num == 3
      waveLoadImageView3.removeFromSuperview
    elsif num == 4
      waveLoadImageView4.removeFromSuperview
    end

  end


  ##### Media picker delegate methods #####
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    track = mediaItemCollection.items[0]
    @engine.sting[@loadingTrack].loadSting(mediaItemCollection.items[0])
    updateLabels

    # fix this crappy bodge too!!!
    if @loadingTrack == 0
      @editView.addSubview(waveLoadImageView0)
    elsif @loadingTrack == 1
      @editView.addSubview(waveLoadImageView1)
    elsif @loadingTrack == 2
      @editView.addSubview(waveLoadImageView2)
    elsif @loadingTrack == 3
      @editView.addSubview(waveLoadImageView3)
    elsif @loadingTrack == 4
      @editView.addSubview(waveLoadImageView4)
    end

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
    self.presentingViewController.playlistDidChange

  end

end