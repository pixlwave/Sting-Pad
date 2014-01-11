class Engine

  # singleton containing all the players for the app.

  attr_accessor :sting, :ipod

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize

    # TODO: use error handler rather than check for nil AVAudioPlayer
    url = Turnkey.unarchive("Sting URL")
    title = Turnkey.unarchive("Sting Title") || "No Sting Loaded"
    artist = Turnkey.unarchive("Sting Artist") || "No Artist"
    cuePoint = Turnkey.unarchive("Cue Point") || 0
    @sting = Sting.new(url, title, artist, cuePoint)

    selectedPlaylist = Turnkey.unarchive("Selected Playlist") || 0
    @ipod = Music.new(selectedPlaylist)

  end

  def playSting

    @ipod.pause
    @sting.play

  end

  def stopSting

    @sting.stop

  end

  def playiPod

    @sting.stop
    @ipod.play

  end

  def pauseiPod

    @ipod.pause

  end

  def self.saveState

    Turnkey.archive(Engine.sharedClient.sting.url, "Sting URL")
    Turnkey.archive(Engine.sharedClient.sting.cuePoint, "Cue Point")
    Turnkey.archive(Engine.sharedClient.sting.title, "Sting Title")
    Turnkey.archive(Engine.sharedClient.sting.artist, "Sting Artist")

    # restore selected playlist by name and not index
    # Turnkey.archive(@playlist, "Playlist")
    Turnkey.archive(Engine.sharedClient.ipod.selectedPlaylist, "Selected Playlist")

  end

end