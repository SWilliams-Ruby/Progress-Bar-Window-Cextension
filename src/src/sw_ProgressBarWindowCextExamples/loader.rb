require File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, 'progress_bar_window_cext_example1.rb')
require File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, 'progress_bar_window_cext_example2.rb')
require File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, 'progress_bar_window_cext_example_tool.rb')
require File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, 'progress_bar_window_cext_example3.rb')


module SW
  module ProgressBarWindowCextExamples
    def self.load_menus()
          
      # Load Menu Items  
      if !@loaded
        toolbar = UI::Toolbar.new "SW ProgressBarWindowCextExamples"
        
        cmd = UI::Command.new("Progress1") {SW::ProgressBarWindowCextExamples.demo1}
        cmd.large_icon = cmd.small_icon =  File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, "icons/example1.png")
        cmd.tooltip = "ProgressBarCextWindow"
        cmd.status_bar_text = "code &block Example"
        toolbar = toolbar.add_item cmd
       
        cmd = UI::Command.new("Progress2") {SW::ProgressBarWindowCextExamples.demo2}
        cmd.large_icon = cmd.small_icon =  File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, "icons/example2.png")
        cmd.tooltip = "ProgressBarCextWindow"
        cmd.status_bar_text = "no code &block example"
        toolbar = toolbar.add_item cmd

        cmd = UI::Command.new("Progress3") {SW::ProgressBarWindowCextExamples.demo3}
        cmd.large_icon = cmd.small_icon =  File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, "icons/example3.png")
        cmd.tooltip = "ProgressBarCextWindow"
        cmd.status_bar_text = "Emergency Brake Example"
        toolbar = toolbar.add_item cmd

        cmd = UI::Command.new("Progress4") {SW::ProgressBarWindowCextExampleTool.start}
        cmd.large_icon = cmd.small_icon =  File.join(SW::ProgressBarWindowCextExamples::PLUGIN_DIR, "icons/example4.png")
        cmd.tooltip = "ProgressBarCextWindow"
        cmd.status_bar_text = "line tool example"
        toolbar = toolbar.add_item cmd


       
        toolbar.show
      @loaded = true
      end
    end
    load_menus()
  end
  
end


