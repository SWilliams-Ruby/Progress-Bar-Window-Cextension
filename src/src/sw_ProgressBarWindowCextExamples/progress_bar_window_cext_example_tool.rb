# This is a modified version of the sketchup example line tool
# Copyright 2016 Trimble Inc
# Licensed under the MIT license
require 'sketchup.rb'


module SW
  module ProgressBarWindowCextExampleTool

    class LineTool

      def activate
        @mouse_ip = Sketchup::InputPoint.new
        @picked_first_ip = Sketchup::InputPoint.new
        update_ui
        UI.messagebox("Draw a line with the pencil tool")
      end

      def deactivate(view)
        view.invalidate
      end

      def resume(view)
        update_ui
        view.invalidate
      end

      def onCancel(reason, view)
        reset_tool
        view.invalidate
      end

      def onMouseMove(flags, x, y, view)
        if picked_first_point?
          @mouse_ip.pick(view, x, y, @picked_first_ip)
        else
          @mouse_ip.pick(view, x, y)
        end
        #view.tooltip = @mouse_ip.tooltip if @mouse_ip.valid?
        view.tooltip = "Draw a Line"
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        # When the user has picked a start point and then picks another point
        # we create an edge
        if picked_first_point?
           draw_fuzzball()
           @picked_first_ip = Sketchup::InputPoint.new
        else
          @picked_first_ip.copy!(@mouse_ip)
        end
      end

      # Here we have hard coded a special ID for the pencil cursor in SketchUp.
      # Normally you would use `UI.create_cursor(cursor_path, 0, 0)` instead
      # with your own custom cursor bitmap:
      #
      #   CURSOR_PENCIL = UI.create_cursor(cursor_path, 0, 0)
      CURSOR_PENCIL = 632
      def onSetCursor
        # Note that `onSetCursor` is called frequently so you should not do much
        # work here. At most you switch between different cursor representing
        # the state of the tool.
        UI.set_cursor(CURSOR_PENCIL)
      end

      def draw(view)
        draw_preview(view)
        @mouse_ip.draw(view) if @mouse_ip.display?
      end

      def getExtents
        bb = Geom::BoundingBox.new
        bb.add(picked_points) if picked_points.size > 0
        bb
      end

      private

      def update_ui
        if picked_first_point?
          Sketchup.status_text = 'Select end point.'
        else
          Sketchup.status_text = 'Select start point.'
        end
      end

      def reset_tool
        @picked_first_ip.clear
        update_ui
      end

      def picked_first_point?
        @picked_first_ip.valid?
      end

      def picked_points
        points = []
        points << @picked_first_ip.position if picked_first_point?
        points << @mouse_ip.position if @mouse_ip.valid?
        points
      end

      def draw_preview(view)
        points = picked_points
        return unless points.size == 2
        view.set_color_from_line(*points)
        view.line_width = 1
        view.line_stipple = ''
        view.draw(GL_LINES, points)
      end

      def draw_fuzzball()
        begin
          Sketchup.active_model.start_operation('Cext Example Tool', true)
         
          SW::ProgressBarWindowCext.new{ |pbar|
            pbar.label = "Adding lines"
            ents = Sketchup.active_model.active_entities
            count = 5000
            
            # using the user's line, draw a fuzzy ball
            center = picked_points[0]
            angle = 180.degrees
            pt0 = center.vector_to(picked_points[1])
           
            count.times{|index|
              vector = Geom::Vector3d.new(rand() - 0.5, rand() - 0.5, rand() - 0.5)
              tr = Geom::Transformation.rotation([0,0,0], vector, angle)           
              pt1 = pt0.transform(tr)
              
              ents.add_line(center, [pt1.x + center.x, pt1.y + center.y, pt1.z + center.z])

              if pbar.update?
                pbar.label= "Remaining: #{count - index}"
                pbar.set_value(100 * index / count)
              end
              
            }  # end count
          } # end ProgressBarWindow.new
          
          Sketchup.active_model.commit_operation
          
        rescue => exception
          Sketchup.active_model.abort_operation
          
          if exception.is_a?(SW::ProgressBarWindowCext::ProgressBarUserAbort)
            puts exception.message
          else
            raise exception
          end
        
        end
      end
    end

    def self.start
      Sketchup.active_model.select_tool(LineTool.new)
    end


  end # ProgressBarExampleTool
end # 
nil
