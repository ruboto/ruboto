require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class ViewConstantsTest < Test::Unit::TestCase
  SRC_DIR = "#{APP_DIR}/src"

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_view_constants
    Dir.chdir APP_DIR do
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
      view_constants_test_filename = "#{APP_DIR}/test/src/ruboto_test_app_activity_test.rb"
      assert File.exists? view_constants_test_filename

      File.open(view_constants_test_filename, 'w') { |f| f << <<EOF }
activity Java::org.ruboto.test_app.RubotoTestAppActivity
java_import "android.view.ViewGroup"
java_import "android.view.Gravity"
java_import "android.os.Build"

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

def view_constant(const)
  View.convert_constant(const.downcase.to_sym)  
end

test('LayoutParams Constants') do |activity|
  ViewGroup::LayoutParams.constants.each do |const|
    assert_equal ViewGroup::LayoutParams.const_get(const), view_constant(const)
  end
end

test('Gravity Constants') do |activity|
  Gravity.constants.each do |const|
    assert_equal Gravity.const_get(const), view_constant(const)
  end
end
EOF

    end
    run_app_tests
  end

end
