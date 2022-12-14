
module SW
  module ProgressBarWindowCextExamples
    def self.demo2()
      begin
        model = Sketchup.active_model.start_operation('Progress Bar Example', true)
        pbar = SW::ProgressBarWindowCext.new
        pbar.show
        
        # create an array of random points 
        points =  []
        1000.times{points << [rand(100),rand(100),rand(100)]}


        # Add cubes to the model, keeping the progress bar updated
        points.each_with_index {|point, index|
          make_cube(point)
          if pbar.update?
            pbar.label= "Remaining: #{points.size - index}"
            pbar.set_value( 100 * index / points.size)
          end
        }

        pbar.hide
        Sketchup.active_model.commit_operation

      rescue => exception
        pbar.hide
        Sketchup.active_model.abort_operation
        
        if exception.is_a?(SW::ProgressBarWindowCext::ProgressBarUserAbort)
          puts exception.message
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

