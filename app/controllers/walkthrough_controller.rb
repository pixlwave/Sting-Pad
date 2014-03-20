class WalkthroughController < UIViewController
  extend IB

  outlet :walkthroughImageView, UIImageView

  def viewDidLoad

    @currentImage = 0
    if UIScreen.mainScreen.bounds.size.height == 568
      @images = ["ThankYou-568h","StkPlaylist-568h", "StkSting-568h", "StkSettings-568h", "EditSting-568h", "EditPlaylist-568h"]
    else
      @images = ["ThankYou", "StkPlaylist", "StkSting", "StkSettings", "EditSting", "EditPlaylist"]
    end
    tap = UITapGestureRecognizer.alloc.initWithTarget(self, action:"imageTapped")

    @walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])
    @walkthroughImageView.userInteractionEnabled = true
    @walkthroughImageView.addGestureRecognizer(tap)

  end

  def imageTapped

    @currentImage += 1
    if @currentImage < @images.count
      UIView.transitionWithView(@walkthroughImageView, duration:0.2, options:UIViewAnimationOptionTransitionCrossDissolve, animations: lambda {@walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])}, completion:nil)
    else
      self.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      presentingViewController.dismissModalViewControllerAnimated(true)
    end

  end

end