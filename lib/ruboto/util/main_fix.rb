# fix main (to an extent)
module Main
  class Program
    module InstanceMethods
      def setup_finalizers
        @finalizers ||= []
        ObjectSpace.define_finalizer(self) do
          while((f = @finalizers.pop)); f.call; end
        end
      end
    end
  end
end