require File.expand_path("test_helper", File.dirname(__FILE__))
require 'test/app_test_methods'

module UpdateTestMethods
  include RubotoTest
  include AppTestMethods

  def setup(old_ruboto_version, old_tools_version)
    @old_ruboto_version = old_ruboto_version
    generate_app :update => "#{old_ruboto_version}_tools_r#{old_tools_version}"
  end

  def teardown
    cleanup_app
  end

  def test_properties_and_ant_file_has_no_duplicates
    Dir.chdir APP_DIR do
      # FIXME(uwe): Cleanup when we stop support Android SDK <= 13
      prop_file = %w{test/ant.properties test/build.properties}.find{|f| File.exists?(f)}
      # FIXME end

      assert File.readlines(prop_file).grep(/\w/).uniq!.nil?, "Duplicate lines in #{prop_file}"
      assert_equal 1, File.readlines('test/build.xml').grep(/<macrodef name="run-tests-helper">/).size, 'Duplicate macro in build.xml'
    end
  end

  def test_icons_are_untouched
    Dir.chdir APP_DIR do
      icon_file_size = File.size('res/drawable-hdpi/icon.png')
      # FIXME(uwe): Simplify when we stop supporting updating from version 0.1.0 and older
      if @old_ruboto_version == '0.1.0'
        assert_equal 4100, icon_file_size
      else
        assert_equal 4032, icon_file_size
      end
      # FIXME end
    end
  end

end
