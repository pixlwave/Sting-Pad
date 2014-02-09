class WalkthroughController < UIViewController
  extend IB

  outlet :walkthroughImageView, UIImageView

  attr_accessor :imageFile

  def viewDidLoad

    @currentImage = 0
    @images = ["StkPlaylist", "StkSting", "EditSting", "EditPlaylist"]
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
      presentingViewController.dismissModalViewControllerAnimated(true)
    end

  end

end