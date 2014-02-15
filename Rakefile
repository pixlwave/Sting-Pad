# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'Stingtk'
  app.version = '0.2'
  app.identifier = 'uk.pixlwave.Stingmtk'
  app.icons = ["Icon.png, Icon@2x.png, Icon-57.png, Icon-57@2x.png"]
  app.prerendered_icon = true
  app.interface_orientations = [:portrait]
  # app.codesign_certificate = 'iPhone Distribution: Douglas Earnshaw (NU8A5Y875P)'
  # app.provisioning_profile = '/Users/Douglas/Documents/RubyMotion/Certificates/SSV_Ad_Hoc.mobileprovision'

  app.frameworks << 'AVFoundation'
  app.frameworks << 'MediaPlayer'
  app.deployment_target = '6.1'
  app.pods do
    pod 'FDWaveformView'
  end
  
end