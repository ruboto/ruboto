require File.expand_path("test_helper", File.dirname(__FILE__))
require 'test/app_test_methods'

class RubotoGenTest < Test::Unit::TestCase
  include AppTestMethods

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_icons_are_updated
    Dir.chdir APP_DIR do
      assert_equal 4032, File.size('res/drawable-hdpi/icon.png')
    end
  end

  def test_gen_class_activity_with_lowercase_should_fail
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class activity --name VeryNewActivity"
      assert_equal 1, $?.exitstatus
      assert !File.exists?('src/org/ruboto/test_app/VeryNewActivity.java')
      assert !File.exists?('src/very_new_activity.rb')
      assert !File.exists?('test/src/very_new_activity_test.rb')
      assert File.read('AndroidManifest.xml') !~ /VeryNewActivity/
    end
  end

end
