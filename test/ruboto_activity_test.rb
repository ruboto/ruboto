require File.expand_path('test_helper', File.dirname(__FILE__))

class RubotoActivityTest < Test::Unit::TestCase
  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_ruboto_activity_as_entry_point
    check_platform_installation
    Dir.chdir APP_DIR do
      #java_source_file = 'src/org/ruboto/test_app/RubotoTestAppActivity.java'
      #source = File.read(java_source_file)
      #assert source.gsub!(/extends org.ruboto.EntryPointActivity/, 'extends org.ruboto.RubotoActivity')
      #File.open(java_source_file, 'w') { |f| f << source }
      system 'rake install'
      #system "adb shell am start -a android.intent.action.MAIN -n org.ruboto.example_test_app/.RubotoActivity"
      system "adb shell am start -n org.ruboto.test_app/org.ruboto.RubotoActivity -e ClassName RubotoTestAppActivity"
      assert_equal 0, $?, "tests failed with return code #$?"
      # FIXME(uwe):  Assert that the activity was started correctly.
    end
  end

end
