
module SW
  module ProgressBarWindowCextExamples
    def self.demo3()
      begin
        SW::ProgressBarWindowCext.new(enable_emergency_brake: true)  { |pbar |
          count = 100000
          a = [1]
          b = []
          pbar.label= "Click Cancel to throw the Emergency Brake"
          count.times { | index |
            b += a 
          }
        }

      rescue => exception
        Sketchup.active_model.abort_operation
        
        if exception.is_a?(SW::ProgressBarWindowCext::ProgressBarUserAbort)
          puts exception.message
        elsif exception.is_a?(SW::ProgressBarWindowCext::ProgressBarEmergencyBrake)
          puts "Emergency Brake Pulled"
        else
          raise exception
        end
        
      end
    end
    
    # add a cube to the model  
    def self.make_cube(point)
      ents = Sketchup.active_model.entities
      grp = ents.add_group
      face = grp.entities.add_face [0,0,0],[2,0,0],[2,2,0],[0,2,0]
      face.pushpull(2)
      grp.material = "red"
      tr = Geom::Transformation.new(point)
      grp.transform!(tr)
    end
    

  end
end
nil

