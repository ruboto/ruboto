require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class ServiceTest < Test::Unit::TestCase
  include RubotoTest
  
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_service_startup
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Service --name RubotoTestService"
      service_filename = "#{APP_DIR}/assets/scripts/ruboto_test_service.rb"
      assert File.exists? service_filename
      File.open(service_filename, 'w'){|f| f << <<EOF}
require 'ruboto'
    
$service.handle_create do
  Thread.start do
    loop do
      sleep 1
      puts "\#{self.class} running..."
    end
  end
  puts "\#{self.class} started."
  android.app.Service::START_STICKY
end

$service.handle_start_command do
  android.app.Service::START_STICKY
end
EOF

      activity_filename = "#{APP_DIR}/assets/scripts/ruboto_test_app_activity.rb"
      s        = File.read(activity_filename)
      s.gsub!(/^(end)$/, "
  startService(android.content.Intent.new($activity.application_context, $package.RubotoTestService.java_class))
\\1\n")
      File.open(activity_filename, 'w') { |f| f << s }
    end
    run_app_tests
  end

end
