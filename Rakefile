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
  app.name = 'Stingmtk'
  app.version = '0.1'
  app.identifier = 'uk.me.digitalfx.Stingmtk'
  app.frameworks << 'AVFoundation'
  app.frameworks << 'MediaPlayer'
  app.deployment_target = '6.1'
  app.icons = ["Icon@2x.png"]
end