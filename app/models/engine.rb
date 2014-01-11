class Engine

  # singleton containing all the players for the app.

  attr_accessor :sting, :ipod

  def self.sharedClient
    Dispatch.once { @instance ||= new }
    @instance
  end

  def initialize

    @sting = Sting.new
    @ipod = Music.new

  end

  def playSting

    @ipod.pause
    @sting.play

  end

  def stopSting

    @sting.stop

  end

  def playiPod

    @sting.stop
    @ipod.play

  end

  def pauseiPod

    @ipod.pause

  end

end