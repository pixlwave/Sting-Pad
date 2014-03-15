class Engine

  # singleton containing all the players for the app.

  attr_accessor :sting, :ipod, :wavesLoaded

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize

    @sting = Array.new(5)

    @sting.each_with_index do |s, i|
      url = Turnkey.unarchive("Sting URL #{i}")
      title = Turnkey.unarchive("Sting Title #{i}") || "Chime"
      artist = Turnkey.unarchive("Sting Artist #{i}") || "Default Sting"
      cuePoint = Turnkey.unarchive("Cue Point #{i}") || 0
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

  def self.saveState

    Engine.sharedClient.sting.each_with_index do |s, i|
      Turnkey.archive(Engine.sharedClient.sting[i].url, "Sting URL #{i}")
      Turnkey.archive(Engine.sharedClient.sting[i].cuePoint, "Cue Point #{i}")
      Turnkey.archive(Engine.sharedClient.sting[i].title, "Sting Title #{i}")
      Turnkey.archive(Engine.sharedClient.sting[i].artist, "Sting Artist #{i}")
    end

    # restore selected playlist by name and not index
    # Turnkey.archive(@playlist, "Playlist")
    Turnkey.archive(Engine.sharedClient.ipod.selectedPlaylist, "Selected Playlist")

  end

end