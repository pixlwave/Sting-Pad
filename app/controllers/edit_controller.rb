class EditController < UIViewController
  extend IB

  outlet :cuePoint, UISlider
  outlet :titleLabel, UILabel
  outlet :artistLabel, UILabel

  def viewDidLoad

    cuePoint.value = self.presentingViewController.getCue
    cuePoint.addTarget(self, action: "setCue", forControlEvents:UIControlEventTouchUpInside)

  end

  def dismiss

    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def loadTrack

    mediaPicker = MPMediaPickerController.alloc.initWithMediaTypes(MPMediaTypeMusic)
    mediaPicker.delegate = self
    mediaPicker.allowsPickingMultipleItems = false
    self.presentModalViewController(mediaPicker, animated:true)

  end


  # Media picker delegate methods
  def mediaPicker(mediaPicker, didPickMediaItems:mediaItemCollection)

    track = mediaItemCollection.items[0]
    self.presentingViewController.loadSting(mediaItemCollection.items[0])
    titleLabel.text = track.valueForProperty(MPMediaItemPropertyTitle)
    artistLabel.text = track.valueForProperty(MPMediaItemPropertyArtist)
    cuePoint.value = 0

    # self.dismissModalViewControllerAnimated(true)
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def mediaPickerDidCancel(mediaPicker)

    # self.dismissModalViewControllerAnimated(true)
    self.dismissViewControllerAnimated(true, completion:nil)

  end

  def setCue

    self.presentingViewController.setCue(cuePoint.value)

  end

end