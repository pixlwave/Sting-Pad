class StingView < UIView
  extend IB

  outlet :view, UIView
  outlet :playButton, UIButton
  outlet :stopButton, UIButton
  outlet :titleLabel, UILabel

  def initWithFrame(frame)

    super
    self.loadNib if self
    
    self

  end
  
  def initWithCoder(aDecoder)

    super
    self.loadNib if self

    self

  end
  
  def loadNib

    # load the contents of the nib
    nibName = NSStringFromClass(self.class)
    nib = UINib.nibWithNibName(nibName, bundle:nil)
    nib.instantiateWithOwner(self, options:nil)

    # add the view loaded from the nib into self.
    self.addSubview(self.view)

  end

end