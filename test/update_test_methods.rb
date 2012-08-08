require File.expand_path("test_helper", File.dirname(__FILE__))
require 'test/app_test_methods'

module UpdateTestMethods
  include RubotoTest

  def setup(old_ruboto_version, old_tools_version)
    @old_ruboto_version = old_ruboto_version
    generate_app :example => "#{old_ruboto_version}_tools_r#{old_tools_version}"
  end

  def teardown
    cleanup_app
  end

  def test_broadcast_receiver
    # FIXME(uwe): Remove check when we stop supporting updating from ruboto_core (Ruboto before version 0.5.2 2011-12-24)
    if Gem::Version.new(@old_ruboto_version) >= Gem::Version.new('0.5.2')
      Dir.chdir APP_DIR do
        puts "Adding a broadcast receiver"
        install_ruboto_gem @old_ruboto_version
        system "ruboto _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
        fail "Creation of broadcast receiver failed" if $? != 0
        assert File.exists? 'src/org/ruboto/test_app/DummyReceiver.java'
        assert File.exists? 'src/dummy_receiver.rb'
        test_file = 'test/src/dummy_receiver_test.rb'
        assert File.exists? test_file

        # FIXME(uwe):  NOOP?
        source = File.read(test_file)
        File.open(test_file, 'w'){|f| f << source}

        update_app
      end
      run_app_tests
    end
    # FIXME end
  end

  def test_broadcast_receiver_updated_twice
    # FIXME(uwe): Remove check when we stop supporting updating from ruboto_core (Ruboto before version 0.5.2 2011-12-24)
    if Gem::Version.new(@old_ruboto_version) >= Gem::Version.new('0.5.2')
      Dir.chdir APP_DIR do
        puts "Adding a broadcast receiver"
        install_ruboto_gem @old_ruboto_version
        system "ruboto _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
        fail "Creation of broadcast receiver failed" if $? != 0
        assert File.exists? 'src/org/ruboto/test_app/DummyReceiver.java'
        assert File.exists? 'src/dummy_receiver.rb'
        test_file = 'test/src/dummy_receiver_test.rb'
        assert File.exists? test_file

        # FIXME(uwe):  NOOP?
        source = File.read(test_file)
        File.open(test_file, 'w'){|f| f << source}

        update_app
        update_app
      end
      run_app_tests
    end
    # FIXME end
  end

  def test_subclass_is_updated
    Dir.chdir APP_DIR do
      puts "Adding a subclass"
      install_ruboto_gem @old_ruboto_version
      system "ruboto _#{@old_ruboto_version}_ gen subclass android.database.sqlite.SQLiteOpenHelper --name MyDatabaseHelper --method_base on"
      fail "Creation of subclass failed" if $? != 0
      assert File.exists? 'src/org/ruboto/test_app/MyDatabaseHelper.java'
      # assert File.exists? 'src/my_database_helper.rb'
      # assert File.exists? 'test/src/my_database_helper_test.rb'

      update_app
      system 'rake debug'
      assert_equal 0, $?
    end
  end

end
