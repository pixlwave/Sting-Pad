class AppDelegate
  
  def application(application, didFinishLaunchingWithOptions:launchOptions)

    application.setIdleTimerDisabled(true)

    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    # @window.tintColor = UIColor.orangeColor if defined? @window.tintColor
    @storyboard = UIStoryboard.storyboardWithName("Storyboard", bundle:nil)
    @window.rootViewController = @storyboard.instantiateInitialViewController
    @window.makeKeyAndVisible

    true

  end

end