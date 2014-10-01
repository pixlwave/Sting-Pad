class WalkthroughController < UIViewController
  extend IB

  outlet :progressLabel, UILabel
  outlet :walkthroughImageView, UIImageView
  outlet :labelSpaceConstraint, NSLayoutConstraint
  outlet :imageTopConstraint, NSLayoutConstraint
  outlet :bottomSpaceConstraint, NSLayoutConstraint

  def viewDidLoad

    super

    # image names and info text
    @images = ["ThankYou", "Playlist", "Sting", "Settings"]

    # start at the beginning and load first image
    @currentImage = 0
    @walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])
    @progressLabel.text = "#{@currentImage + 1} of #{@images.count}"

    if UIScreen.mainScreen.bounds.size.height < 568
      @labelSpaceConstraint.constant = 3
      @imageTopConstraint.constant = 10
      @bottomSpaceConstraint.constant = 0
    end

    # recognise image view taps
    tap = UITapGestureRecognizer.alloc.initWithTarget(self, action:"screenTapped")
    self.view.userInteractionEnabled = true
    self.view.addGestureRecognizer(tap)

  end

  def screenTapped

    # go to the next image until end, then dismiss self
    @currentImage += 1
    if @currentImage < @images.count
      UIView.transitionWithView(@walkthroughImageView, duration: 0.2, options: UIViewAnimationOptionTransitionCrossDissolve, animations: lambda {@walkthroughImageView.image = UIImage.imageNamed("Walkthrough/"+@images[@currentImage])}, completion: nil)
      UIView.transitionWithView(@progressLabel, duration:0.2, options: UIViewAnimationOptionTransitionCrossDissolve, animations: lambda {@progressLabel.text = "#{@currentImage + 1} of #{@images.count}"}, completion: nil)
    else
      self.modalTransitionStyle = UIModalTransitionStyleCoverVertical
      presentingViewController.dismissModalViewControllerAnimated(true)
    end

  end

  # walkthrough version
  def self.version
    1.1
  end

end