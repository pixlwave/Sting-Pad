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
  app.version = '0.6'
  app.identifier = 'uk.pixlwave.Stingmtk'
  app.deployment_target = '6.1'
  
  app.icons = ["Icon.png", "Icon@2x.png", "Icon-57.png", "Icon-57@2x.png"]
  app.prerendered_icon = true
  app.interface_orientations = [:portrait]
  
  app.development do
    app.provisioning_profile = '/Users/Douglas/Documents/RubyMotion/Certificates/Stingmtkdevelopment.mobileprovision'
  end
  app.release do
    app.provisioning_profile = '/Users/Douglas/Documents/RubyMotion/Certificates/Stingmtk.mobileprovision'
    # app.codesign_certificate = 'iPhone Distribution: Douglas Earnshaw (NU8A5Y875P)'
  end

  app.frameworks << 'AVFoundation'
  app.frameworks << 'MediaPlayer'

  app.vendor_project('vendor/FDWaveformView', :static, :cflags => '-fobjc-arc')
  
end