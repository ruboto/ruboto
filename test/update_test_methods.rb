require File.expand_path('test_helper', File.dirname(__FILE__))

module UpdateTestMethods
  include RubotoTest

  def setup(old_ruboto_version, old_tools_version)
    @old_ruboto_version = old_ruboto_version
    generate_app example: "#{old_ruboto_version}_tools_r#{old_tools_version}"
  end

  def teardown
    cleanup_app
  end

  # FIXME(uwe):  We have no solution for legacy apps <= 0.9.0.rc1 and new RubotoCore >= 0.4.9.
  unless Gem::Version.new(@old_ruboto_version) <= Gem::Version.new('0.9.0.rc.1')
    def test_an_unchanged_app_succeeds_loading_stdlib
      # FIXME(uwe): Remove when we stop supporting legacy Ruboto 0.9.0.rc.1 apps and older
      if Gem::Version.new(@old_ruboto_version) <= Gem::Version.new('0.9.0.rc.1')
        Dir.chdir "#{APP_DIR}/test" do
          test_props = File.read('ant.properties')
          test_props.gsub! /^tested.project.dir=.*$/, 'tested.project.dir=../'
          File.open('ant.properties', 'w') { |f| f << test_props }
        end
      end
      assert_code "require 'base64'"
      run_app_tests
    end
  end

  # FIXME(uwe): Older projects generated code that is no longer compatible/correct
  # FIXME(uwe): Remove check when we stop support for updating from Ruboto 0.10.0.rc.0 and older
  unless Gem::Version.new(@old_ruboto_version) <= Gem::Version.new('0.10.0.rc.0')
    def test_broadcast_receiver
      Dir.chdir APP_DIR do
        puts 'Adding a broadcast receiver'
        install_ruboto_gem @old_ruboto_version
        system "ruboto _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
        fail 'Creation of broadcast receiver failed' if $? != 0
        assert File.exists? 'src/org/ruboto/test_app/DummyReceiver.java'
        assert File.exists? 'src/dummy_receiver.rb'
        test_file = 'test/src/dummy_receiver_test.rb'
        assert File.exists? test_file
        update_app
      end
      run_app_tests
    end

    def test_broadcast_receiver_updated_twice
      Dir.chdir APP_DIR do
        puts 'Adding a broadcast receiver'
        install_ruboto_gem @old_ruboto_version
        system "ruboto _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
        fail 'Creation of broadcast receiver failed' if $? != 0
        assert File.exists? 'src/org/ruboto/test_app/DummyReceiver.java'
        assert File.exists? 'src/dummy_receiver.rb'
        test_file = 'test/src/dummy_receiver_test.rb'
        assert File.exists? test_file
        update_app
        update_app
      end
      run_app_tests
    end
  end

  def test_subclass_is_updated
    Dir.chdir APP_DIR do
      puts 'Adding a subclass'
      install_ruboto_gem @old_ruboto_version
      system "ruboto _#{@old_ruboto_version}_ gen subclass android.database.sqlite.SQLiteOpenHelper --name MyDatabaseHelper --method_base on"
      fail 'Creation of subclass failed' if $? != 0
      assert File.exists? 'src/org/ruboto/test_app/MyDatabaseHelper.java'
      if Gem::Version.new(@old_ruboto_version) >= Gem::Version.new('0.8.1.rc.0')
        assert File.exists? 'src/my_database_helper.rb'
        assert File.exists? 'test/src/my_database_helper_test.rb'
      end
      update_app
      assert File.exists? 'src/my_database_helper.rb'
      assert File.exists? 'test/src/my_database_helper_test.rb'
      system 'rake debug'
      assert_equal 0, $?
    end
  end

  private

  def assert_code(code)
    filename = 'src/ruboto_test_app_activity.rb'
    Dir.chdir APP_DIR do
      s = File.read(filename)
      raise 'Code injection failed!' unless s.gsub!(/(require 'ruboto\/widget')/, "\\1\n#{code}")
      File.open(filename, 'w') { |f| f << s }
    end
  end

end
