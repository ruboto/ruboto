require File.expand_path('test_helper', File.dirname(__FILE__))

class RubotoActivityTest < Minitest::Test
  def setup
    super
    generate_app
  end

  def teardown
    cleanup_app
    super
  end

  def test_ruboto_activity_as_entry_point
    check_platform_installation
    Dir.chdir APP_DIR do
      package = 'org.ruboto.test_app'
      app_element = verify_manifest(reload: true).elements['application']
      activity_element = app_element.elements["activity[@android:name='org.ruboto.RubotoActivity']"]
      activity_element.attributes['android:exported'] = true
      save_manifest
      system 'rake install'
      system "adb shell am start -n #{package}/org.ruboto.RubotoActivity -e ClassName RubotoTestAppActivity"
      assert_equal 0, $?, "tests failed with return code #$?"
      # FIXME(uwe):  Assert that the activity was started correctly.
    end
  end

end
