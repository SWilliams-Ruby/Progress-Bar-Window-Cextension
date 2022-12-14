# SW::ProgressBarWindowCext.new { | pbar |
#   100.times { | i |
#     # do something smart
#     sleep(0.02)
#     if pbar.update?
#       pbar.label= "Remaining: #{ 100 - i  }"
#       pbar.set_value( i )
#     end
#    }
# }


module SW
  module ProgressBarWindowCext

    # Exception class for Progress bar user code errors
    class ProgressBarError < RuntimeError; end

    # Exception class for Progress bar user abort
    class ProgressBarUserAbort < RuntimeError; end
    
    # Exception class for Progress bar Eemergency brake
    class ProgressBarEmergencyBrake < RuntimeError; end
    
    def self.new( enable_emergency_brake: false, &block ) 
      @enable_emergency_brake = enable_emergency_brake
      @update_interval = 0.02
      @user_cancelled = false
      @update_timer = SingleShotTimer.new()
      call_user_block(block) if block
      self
    end # initialization
    
    # Call the the user's block. The progressbar instance will be
    # passed as the argument to the block
    def self.call_user_block(block)
      begin
        show()
        block.call(self)
      ensure
        hide()
      end
    end
    
    def self.show()
      SWProgressBarCext.show()
      enable_emergency_brake() if @enable_emergency_brake
      @update_timer.run( @update_interval )
    end
   
    def self.hide()
      disable_emergency_brake()
      SWProgressBarCext.hide()
    end
    
    def self.label= ( label )
      raise ProgressBarUserAbort, 'User Cancelled' if @user_cancelled
      SWProgressBarCext.label = label
    end
    
    # Has the user clicked cancel?
    #
    def self.cancelled?()
      SWProgressBarCext.cancelled?()
    end
    
    # Place the progress bar at 'value' percent.
    # 'value' between 0 and 100 inclusive
    #
    def self.set_value(value)
      raise ProgressBarUserAbort, 'User Cancelled' if cancelled?
      raise ProgressBarError, "Value must be a Numeric type" \
        unless value.is_a?(Numeric)
      raise ProgressBarError, "Value must be between 0 and 100" \
        if (value < 0.0) || (value > 100.0)
        @value = value
        SWProgressBarCext.set_position( value )
    end
    
    # Advance the progress bar by 'value' percent.
    # 'value' between 0 and 100 inclusive
    #
    def self.advance_value(value)
      raise ProgressBarUserAbort, 'User Cancelled' if cancelled?
      raise ProgressBarError, "Value must be a Numeric type" \
        unless value.is_a?(Numeric)
      raise ProgressBarError, "Value must be between 0 and 100" \
        if (value < 0.0) || (value > 100.0)
      @value += value
      @value = 100.0 if @value > 100.0
    end
    
    # The update? method returns true approximately every @update_interval.
    #
    def self.update?
      raise ProgressBarUserAbort, 'User Cancelled' if cancelled?
      if @update_timer.timed_out?
        @update_timer.run( @update_interval )
        true     
      else
        false
      end  
    end
    
    # Start the emergency brake thread
    #
    #   When the user clicks Cancel a countdowmn timer is started. If the timer
    #   reaches 0 before the emergency break is disabled() the thread will
    #   raise a ProgressBarEmergencyBrake exception on the main thread
    #
    #   The thread will quietly die after 1/2 an hour if it somehow 
    #   becomes orphaned.
    #
    def self.enable_emergency_brake()
      # stop any running emergency break thread, defensive programming
      disable_emergency_brake() 
      countdown = 5  # seconds
      main_thread = Thread.current
      
      @emergency_brake_thr = Thread.new() { 
        1800.times {            
          sleep(1)
          if SWProgressBarCext.cancelled?
            countdown.times { | i |
              SWProgressBarCext.label = "Aborting in #{ countdown - i } seconds"
              sleep(1)
            }
            main_thread.raise(ProgressBarEmergencyBrake, "User Canceled")
            break # end the loop
          end
        } 
      }
    end
     
    # Stop the emergency brake before it times out
    #
    def self.disable_emergency_brake()
      @emergency_brake_thr.exit if @emergency_brake_thr
    end
  
    # A Single Shot timer has three states
    #   :idle
    #   :running
    #   :timed_out
    #
    # The state will progress to :running only if it is not :running
    # The state will progress to :timed_out only if it is :running
    # i.e. the timer must be :idle or :timed_out to start another cycle. 
    #
    # Methods:
    #   new => self   new instance
    #   run(Numeric) => self  # The duration is in seconds. 
    #   reset => self # reset the timer to :idle
    #   state => Symbol (the state)
    #   timed_out? => Boolean # true if state is :timed_out
    #
    # Example
    #   duration = 1.0
    #   timer = SW::Timers::SingleShotTimer.new
    #   timer.run(duration)
    #
    #   loop 
    #     ...
    #     if timer.timed_out?
    #       do_something()
    #       timer.run(duration) # restart timer
    #     ensure
    #   end # end of loop
    #
    class SingleShotTimer
      @state = :idle
      @thr = nil
      class SingleShotTimerError < RuntimeError; end

      def run(duration = nil)
        if @state == :running
          raise SingleShotTimerError, 'Cannot Start Timer, State is :running' 
        elsif !duration.is_a?(Numeric)
          raise SingleShotTimerError, 'Cannot Start Timer, Duration must be a Numeric Type' 
        elsif duration.is_a?(Complex)
          raise SingleShotTimerError, 'Cannot Start Timer, Duration is too Complex' 
        else
          start_thread(duration)
        end
        self 
      end
      
      def start_thread(duration)
        @state = :running
        @thr = Thread.new { 
          sleep(duration)
          @state = :timed_out
        }
      end
      protected :start_thread
      
      def reset()
        @thr.exit if @thr
        @state = :idle
        self
      end
      
      def state()
        @state
      end
      
      def timed_out?
        @state == :timed_out
      end
    end # SingleShot

  end
end
