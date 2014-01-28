class Music

  attr_reader :allPlaylists, :playlist, :selectedPlaylist

  def initialize(selectedPlaylist)

    @musicPlayer = MPMusicPlayerController.iPodMusicPlayer
    @allPlaylists = getAllPlaylists
    @selectedPlaylist = selectedPlaylist
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
    play # unless @musicPlayer.playbackState == MPMusicPlaybackStatePlaying

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
    
    Engine.saveState

  end

end