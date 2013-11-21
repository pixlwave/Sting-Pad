class Music

  attr_reader :allPlaylists, :playlist, :selectedPlaylist

  def initialize

    @musicPlayer = MPMusicPlayerController.iPodMusicPlayer
    @allPlaylists = getAllPlaylists
    @playlist = @allPlaylists[0]
    @musicPlayer.setQueueWithItemCollection(@playlist)
    @selectedPlaylist = 0

  end

  def play

    Sting::Player.stop
    @musicPlayer.play

  end

  def pause

    @musicPlayer.pause

  end

  def Previous

    @musicPlayer.skipToPreviousItem

  end

  def Next

    @musicPlayer.skipToNextItem

  end

  def playItem(index)

    @musicPlayer.setNowPlayingItem(@playlist.items[index])
    play unless @musicPlayer.playbackState == MPMusicPlaybackStatePlaying

  end

  def getNamedPlaylist(name)

    selectedPlaylist = nil

    @allPlaylists.each do |playlist|
      if playlist.valueForProperty(MPMediaPlaylistPropertyName) == name
        selectedPlaylist = playlist
      end
    end

    selectedPlaylist

  end

  def getAllPlaylists

    playlistsQuery = MPMediaQuery.playlistsQuery
    playlistsArray = playlistsQuery.collections
    
    playlistsArray

  end

  def usePlaylist(index)

    @playlist = @allPlaylists[index]
    @musicPlayer.setQueueWithItemCollection(@playlist)
    @selectedPlaylist = index

  end

  Player = Music.new


  # def archive

  #   # restore selected playlist by name and not index
  #   Turnkey.archive(@playlist, "Playlist")
  #   Turnkey.archice(@selectedPlaylist, "Selected Playlist")

  # end

  # def unarchive

  #   playlist = Turnkey.unarchive("Playlist")
  #   selectedPlaylist = Turnkey.unarchive("Selected Playlist")

  #   @playlist = playlist if playlist
  #   @selectedPlaylist = selectedPlaylist if selectedPlaylist

  # end

end