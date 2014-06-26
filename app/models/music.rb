class Music

  attr_reader :allPlaylists, :playlist, :selectedPlaylist

  def initialize(selectedPlaylist)

    @musicPlayer = MPMusicPlayerController.iPodMusicPlayer
    @allPlaylists = getAllPlaylists
    @selectedPlaylist = selectedPlaylist
    @playlist = @allPlaylists[@selectedPlaylist]
    @musicPlayer.setQueueWithItemCollection(@playlist)
    @musicPlayer.beginGeneratingPlaybackNotifications
    MPMediaLibrary.defaultMediaLibrary.beginGeneratingLibraryChangeNotifications

  end

  def play

    @musicPlayer.play

  end

  def pause

    @musicPlayer.pause

  end

  def previous

    @musicPlayer.skipToPreviousItem

  end

  def next

    @musicPlayer.skipToNextItem

  end

  def playItem(index)

    @musicPlayer.setNowPlayingItem(@playlist.items[index])
    play # unless @musicPlayer.playbackState == MPMusicPlaybackStatePlaying

  end

  def nowPlayingItem

    @musicPlayer.nowPlayingItem

  end

  def isPlaying

    # if @musicPlayer.playbackState == MPMusicPlaybackStatePlaying
    # workaround: http://stackoverflow.com/questions/18910207/ios7-mpmusicplayercontroller-states-incorrect

    if @musicPlayer.currentPlaybackRate != 0
      return true
    else
      return false
    end

  end

  def toggleShuffle

    if shuffleState
      @musicPlayer.shuffleMode = MPMusicShuffleModeOff
    else
      @musicPlayer.shuffleMode = MPMusicShuffleModeSongs
    end

  end

  def shuffleState

    if @musicPlayer.shuffleMode == MPMusicShuffleModeOff
      return false
    else
      return true
    end

  end

  def refreshPlaylists

    # gets all playlists in the media library
    @allPlaylists = getAllPlaylists

    # find currect playlist in the collection and update
    # if not found select first playlist
    @selectedPlaylist = @allPlaylists.index(@playlist) || 0
    @playlist = @allPlaylists[@selectedPlaylist]

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