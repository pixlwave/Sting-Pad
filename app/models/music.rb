class Music

  attr_reader :playlist, :allPlaylists

  def initialize

    @musicPlayer = MPMusicPlayerController.iPodMusicPlayer
    @allPlaylists = getAllPlaylists
    @playlist ||= @allPlaylists[0]
    @musicPlayer.setQueueWithItemCollection(@playlist)

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

  end

  Player = Music.new

end