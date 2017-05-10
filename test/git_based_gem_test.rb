require File.expand_path('test_helper', File.dirname(__FILE__))
require 'bigdecimal'
require 'test/app_test_methods'

class GitBasedGemTest < Minitest::Test
  def setup
    generate_app
    Dir.chdir APP_DIR do
      File.write('Gemfile.apk', <<~GEMFILE)
        source 'http://rubygems.org/'
        gem 'example_gem', github: 'ruboto/example_gem'
      GEMFILE
    end
  end

  def teardown
    cleanup_app
  end

  def test_example_gem
    Dir.chdir APP_DIR do
      File.open('src/ruboto_test_app_activity.rb', 'w') { |f| f << <<EOF }
require 'ruboto/widget'
require 'example_gem'

ruboto_import_widgets :LinearLayout, :ListView, :TextView

class RubotoTestAppActivity
  def onCreate(bundle)
    super
    setTitle 'example_gem loaded OK!'

    self.content_view =
        linear_layout :orientation => :vertical, :gravity => :center do
          text_view :id => 42, :text => title, :text_size => 48.0, :gravity => :center
        end
  end
end
EOF

      File.open('test/src/ruboto_test_app_activity_test.rb', 'w') { |f| f << <<EOF }
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

test("activity starts") do |activity|
  assert_equal 'example_gem loaded OK!', @text_view.text.to_s
end
EOF

    end

    run_app_tests
  end

end
