require File.expand_path("test_helper", File.dirname(__FILE__))
require 'test/app_test_methods'

module UpdatedExampleTestMethods
  include RubotoTest
  include AppTestMethods

  def setup(old_ruboto_version, old_tools_version)
    @old_ruboto_version = old_ruboto_version
    generate_app :example => "#{old_ruboto_version}_tools_r#{old_tools_version}", :update => true
  end

  def teardown
    cleanup_app
  end

  def test_properties_and_ant_file_has_no_duplicates
    Dir.chdir APP_DIR do
      assert File.readlines('test/ant.properties').grep(/\w/).uniq!.nil?, "Duplicate lines in test/ant.properties"
      assert_equal 1, File.readlines('test/build.xml').grep(/<macrodef name="run-tests-helper">/).size, 'Duplicate macro in test/build.xml'
    end
  end

  def test_icons_are_untouched
    Dir.chdir APP_DIR do
      icon_file_size = File.size('res/drawable-hdpi/icon.png')
      assert_equal 4032, icon_file_size
    end
  end

end
