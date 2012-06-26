require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class ServiceTest < Test::Unit::TestCase
  SRC_DIR = "#{APP_DIR}/src"

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_service_startup
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Service --name RubotoTestService"

      activity_filename = "#{SRC_DIR}/ruboto_test_app_activity.rb"
      assert File.exists? activity_filename
      File.open(activity_filename, 'w') { |f| f << <<EOF }
require 'ruboto/activity'
require 'ruboto/widget'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class RubotoTestAppActivity
  include Ruboto::Activity

  def on_create(bundle)
    $ruboto_test_app_activity = self
    set_title 'Domo arigato, Mr Ruboto!'

    self.content_view =
        linear_layout :orientation => :vertical do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, :width => :fill_parent,
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          button :text => 'M-x butterfly', :width => :fill_parent, :id => 43, :on_click_listener => proc { butterfly }
        end
  rescue
    puts "Exception creating activity: \#{$!}"
    puts $!.backtrace.join("\\n")
  end

  def set_text(text)
    @text_view.text = text
  end

  private

  def butterfly
    puts 'butterfly'
    Thread.start do
      begin
        startService(android.content.Intent.new(application_context, $package.RubotoTestService.java_class))
      rescue Exception
        puts "Exception starting the service: \#{$!}"
        puts $!.backtrace.join("\\n")
      end
    end
    puts 'butterfly OK'
  end

end
EOF

      service_filename = "#{SRC_DIR}/ruboto_test_service.rb"
      assert File.exists? service_filename
      File.open(service_filename, 'w') { |f| f << <<EOF }
require 'ruboto/service'

class RubotoTestService
  TARGET_TEXT = 'What hath Matz wrought!'
  include Ruboto::Service
  def on_create
    puts "service on_create"
    Thread.start do
      loop do
        sleep 1
        puts "\#{self.class} running..."
      end
    end
    puts "\#{self.class} started."

    $ruboto_test_app_activity.set_title 'on_create'

    android.app.Service::START_STICKY
  end

  def on_start_command(intent, flags, start_id)
    puts "service on_start_command(\#{intent}, \#{flags}, \#{start_id})"
    getApplication()
    getApplication
    get_application
    application

    $ruboto_test_app_activity.set_title 'on_start_command'
    $ruboto_test_app_activity.set_text TARGET_TEXT

    android.app.Service::START_STICKY
  end
end
EOF

      service_test_filename = "#{APP_DIR}/test/src/ruboto_test_app_activity_test.rb"
      assert File.exists? service_test_filename
      File.open(service_test_filename, 'w') { |f| f << <<EOF }
activity Java::org.ruboto.test_app.RubotoTestAppActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test 'button changes text', :ui => false do |activity|
  button = activity.findViewById(43)
  puts 'Clicking...'
  activity.run_on_ui_thread{button.performClick}
  puts 'Clicked!'
  start = Time.now
  loop do
    break if @text_view.text == 'What hath Matz wrought!' || (Time.now - start > 60)
    sleep 1
  end
  assert_equal 'What hath Matz wrought!', @text_view.text
end
EOF

    end
    run_app_tests
  end

end
