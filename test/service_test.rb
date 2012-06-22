require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class ServiceTest < Test::Unit::TestCase
  SRC_DIR ="#{APP_DIR}/src"

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_service_startup
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Service --name RubotoTestService"
      service_filename = "#{SRC_DIR}/ruboto_test_service.rb"
      assert File.exists? service_filename
      File.open(service_filename, 'w') { |f| f << <<EOF }
require 'ruboto/service'

class RubotoTestService
  include Ruboto::Service
  def on_create
    Thread.start do
      loop do
        sleep 1
        puts "\#{self.class} running..."
      end
    end
    puts "\#{self.class} started."
    android.app.Service::START_STICKY
  end

  def on_start_command(intent, flags, start_id)
    android.app.Service::START_STICKY
  end
end
EOF

      activity_filename = "#{SRC_DIR}/ruboto_test_app_activity.rb"
      s                 = File.read(activity_filename)
      s.gsub!(/^(end)$/, "
  def on_resume
    startService(android.content.Intent.new(application_context, $package.RubotoTestService.java_class))
  end

  def on_pause
    stopService(android.content.Intent.new(application_context, $package.RubotoTestService.java_class))
  end
\\1\n")
      File.open(activity_filename, 'w') { |f| f << s }
    end
    run_app_tests
  end

end
