class AppDelegate
  
  def application(application, didFinishLaunchingWithOptions:launchOptions)

    # prevent device from going to sleep
    application.setIdleTimerDisabled(true)

    # allow music to play whilst muted
    AVAudioSession.sharedInstance.setCategory(AVAudioSessionCategoryPlayback, error:nil)

    # prevent app launch from killing iPod by allowing mixing
    allowMixing = Pointer.new(:long)
    allowMixing[0] = true
    AudioSessionSetProperty(KAudioSessionProperty_OverrideCategoryMixWithOthers, 4, allowMixing)

    # Sting::Player = Turnkey.unarchive("StingPlayer")
    # Music::Player = Turnkey.unarchive("MusicPlayer")

    # set up main window and begin!
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @storyboard = UIStoryboard.storyboardWithName("Storyboard", bundle:nil)
    @window.rootViewController = @storyboard.instantiateInitialViewController
    @window.makeKeyAndVisible

    puts "hello world launch"

    true

  end

  def applicationDidBecomeActive(application)

    # Sting::Player.unarchive
    # player = Turnkey.unarchive("Music Player")
    # Music::player = player if player

  end

  def applicationDidEnterBackground(application)

    # Sting::Player.archive
    # Turnkey.archive(Music::Player, "Music Player")

  end

end