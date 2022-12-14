require 'pathname'

ver = "Release (2.2)"
ver = "Release (2.5)" if  RUBY_VERSION.include?("2.5.")
ver = "Release (2.7)" if  RUBY_VERSION.include?("2.7.")

path = Pathname.new(SW::ProgressBarWindowCextExt::PLUGIN_DIR).parent.parent + ver + "x64" + "SWProgressBar"
require path

require File.join(SW::ProgressBarWindowCextExt::PLUGIN_DIR, 'ProgressBarWindowCext')
