class Music

  attr_reader :allPlaylists, :playlist, :selectedPlaylist

  def initialize

    @musicPlayer = MPMusicPlayerController.iPodMusicPlayer
    @allPlaylists = getAllPlaylists
    @selectedPlaylist = Turnkey.unarchive("Selected Playlist") || 0
    @playlist = @allPlaylists[@selectedPlaylist]
    @musicPlayer.setQueueWithItemCollection(@playlist)

  end

  def play

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
    
    saveState

  end

  def saveState

    # restore selected playlist by name and not index
    # Turnkey.archive(@playlist, "Playlist")
    Turnkey.archive(@selectedPlaylist, "Selected Playlist")

  end

end