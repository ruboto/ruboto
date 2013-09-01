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
      icon_file = Dir['res/drawable-hdpi/{icon,ic_launcher}.png'][0]
      icon_file_size = File.size(icon_file)
      # FIXME(uwe): Simplify when we stop support for updating from Ruboto 0.12.0 and older
      assert_equal (Gem::Version.new(@old_ruboto_version) <= Gem::Version.new('0.12.0') ? 4032 : 3834),
                   icon_file_size
      # EMXIF
    end
  end

  # FIXME(uwe): Remove when we stop updating from Ruboto 0.8.1 and older.
  def test_dexmaker_jar_is_removed
    Dir.chdir APP_DIR do
      assert_equal [], Dir['libs/dexmaker*.jar']
    end
  end
  # EMXIF

end
