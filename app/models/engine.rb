class Engine

  # singleton containing all the players for the app.

  attr_accessor :sting, :ipod

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize

    @sting = Array.new(3)

    @sting.each_with_index do |s, i|
      url = Turnkey.unarchive("Sting URL #{i}")
      title = Turnkey.unarchive("Sting Title #{i}") || "No Sting Loaded"
      artist = Turnkey.unarchive("Sting Artist #{i}") || "No Artist"
      cuePoint = Turnkey.unarchive("Cue Point #{i}") || 0
      @sting[i] = Sting.new(url, title, artist, cuePoint)
    end

    selectedPlaylist = Turnkey.unarchive("Selected Playlist") || 0
    @ipod = Music.new(selectedPlaylist)

  end

  def playSting(selectedSting)

    @ipod.pause
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