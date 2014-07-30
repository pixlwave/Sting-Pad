class WalkthroughController < UIViewController
  extend IB

  outlet :walkthroughImageView, UIImageView

  def viewDidLoad

    super

    # use appropriate images for the screen size
    if UIScreen.mainScreen.bounds.size.height == 568
      @images = ["ThankYou-568h","StkPlaylist-568h", "StkSting-568h", "StkSettings-568h", "EditSting-568h", "EditPlaylist-568h"]
    else
      @images = ["ThankYou", "StkPlaylist", "StkSting", "StkSettings", "EditSting", "EditPlaylist"]
    end

    # start at the beginning and load first image
    @currentImage = 0
    @walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])

    # recognise image view taps
    tap = UITapGestureRecognizer.alloc.initWithTarget(self, action:"imageTapped")
    @walkthroughImageView.userInteractionEnabled = true
    @walkthroughImageView.addGestureRecognizer(tap)

  end

  def imageTapped

    # go to the next image until end, then dismiss self
    @currentImage += 1
    if @currentImage < @images.count
      UIView.transitionWithView(@walkthroughImageView, duration:0.2, options:UIViewAnimationOptionTransitionCrossDissolve, animations: lambda {@walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])}, completion:nil)
    else
      self.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      presentingViewController.dismissModalViewControllerAnimated(true)
    end

  end

  # walkthrough version
  def self.version
    1.0
  end

end