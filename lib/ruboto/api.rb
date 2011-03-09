require 'ruboto/util/log_action'
require 'ruboto/util/scan_in_api'

module Ruboto
  module API
    class << self
      include Ruboto::Util::LogAction
      include Ruboto::Util::ScanInAPI
  
      def api
        @api ||= begin
          log_action("Loading Android API") do
            api = File.expand_path(Ruboto::GEM_ROOT + "/lib/java_class_gen/android_api.xml")
            abort "cannot find android_api.xml to extract info from it." unless  File.exists? api
            scan_in_api(File.read(api))["api"][0]
          end
        end
      end
    end
  end
end