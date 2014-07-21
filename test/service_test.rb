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
require 'ruboto/service'

ruboto_import_widgets :Button, :LinearLayout, :TextView

class RubotoTestAppActivity
  def onCreate(bundle)
    super
    $ruboto_test_app_activity = self
    set_title 'Domo arigato, Mr Ruboto!'

    self.content_view =
        linear_layout :orientation => :vertical do
          @text_view = text_view :text    => 'What hath Matz wrought?', :id => 42, 
                                 :layout => {:width => :fill_parent},
                                 :gravity => android.view.Gravity::CENTER, :text_size => 48.0
          button :text => 'M-x butterfly', :layout => {:width => :fill_parent}, 
                 :id => 43, :on_click_listener => proc { butterfly }
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
        start_ruboto_service("RubotoTestService")
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
class RubotoTestService
  TARGET_TEXT = 'What hath Matz wrought!'

  def onCreate
    puts "service onCreate"
    Thread.start do
      loop do
        sleep 1
        puts "\#{self.class} running..."
      end
    end
    puts "\#{self.class} started."

    $ruboto_test_app_activity.set_title 'onCreate'

    android.app.Service::START_STICKY
  end

  def onStartCommand(intent, flags, start_id)
    puts "service on_start_command(\#{intent}, \#{flags}, \#{start_id})"
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
