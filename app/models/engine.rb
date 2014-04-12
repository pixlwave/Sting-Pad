class Engine

  # singleton containing all the players for the app.

  attr_accessor :sting, :ipod, :wavesLoaded

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize

    @sting = Array.new(5)
    @wavesLoaded = Array.new(@sting.size)

    @sting.each_with_index do |s, i|
      url = Turnkey.unarchive("Sting #{i} URL")
      title = Turnkey.unarchive("Sting #{i} Title") || "Chime"
      artist = Turnkey.unarchive("Sting #{i} Artist") || "Default Sting"
      cuePoint = Turnkey.unarchive("Sting #{i} Cue Point") || 0
      @sting[i] = Sting.new(url, title, artist, cuePoint)
    end

    selectedPlaylist = Turnkey.unarchive("Selected Playlist") || 0
    @ipod = Music.new(selectedPlaylist)

    @playingSting = 0

  end

  def playSting(selectedSting)

    @ipod.pause
    @sting[@playingSting].stop if selectedSting != @playingSting
    @sting[selectedSting].play
    @playingSting = selectedSting

  end

  def stopSting

    @sting[@playingSting].stop

  end

  def playiPod

    @sting[@playingSting].stop
    @ipod.play

  end

  def playiPodItem(index)

    @sting[@playingSting].stop
    @ipod.playItem(index)

  end

  def pauseiPod

    @ipod.pause

  end

  def setStingDelegates(object)

    @sting.each do |s|
      s.delegate = object
    end

  end

  def self.saveState

    Engine.sharedClient.sting.each_with_index do |s, i|
      Turnkey.archive(Engine.sharedClient.sting[i].url, "Sting #{i} URL")
      Turnkey.archive(Engine.sharedClient.sting[i].cuePoint, "Sting #{i} Cue Point")
      Turnkey.archive(Engine.sharedClient.sting[i].title, "Sting #{i} Title")
      Turnkey.archive(Engine.sharedClient.sting[i].artist, "Sting #{i} Artist")
    end

    # This needs to be changed to save by playlist id or similar
    # Would enable checking of playlist properly if order changed
    Turnkey.archive(Engine.sharedClient.ipod.selectedPlaylist, "Selected Playlist")

  end

end