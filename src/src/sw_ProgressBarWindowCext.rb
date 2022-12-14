#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------

require "extensions.rb"

module SW
  module ProgressBarWindowCextExt
    path = __FILE__
    path.force_encoding("UTF-8") if path.respond_to?(:force_encoding)

    PLUGIN_ID = File.basename(path, ".rb")
    PLUGIN_DIR = File.join(File.dirname(path), PLUGIN_ID)
    EXTENSION = SketchupExtension.new(
      "SW ProgressWindowCext",
      File.join(PLUGIN_DIR, "loader")
    )
    EXTENSION.creator     = "S. Williams"
    EXTENSION.description = "A Sketchup ProgressBarWindowCext "
    EXTENSION.version     = "1.0.1"
    EXTENSION.copyright   = "#{EXTENSION.creator} Copyright (c) 2022"
    Sketchup.register_extension(EXTENSION, true)

  end
end

