module Ruboto
  module Util
    module LogAction
      ###########################################################################
      #
      # log_action: put text to stdout around the execution of a block
      #
      
      def log_action(initial_text, final_text="Done.", &block)
        $stdout.sync = true

        print initial_text, "..."
        result = yield
        puts final_text
        
        result
      end
    end
  end
end
