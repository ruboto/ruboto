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
    Dir.chdir APP_DIR do

      # FIXME(uwe): Remove check when we stop supporting updating from ruboto_core (Ruboto before version 0.5.2 2011-12-24)
      if Gem::Version.new(@old_ruboto_version) >= Gem::Version.new('0.5.2')
        puts "Adding a broadcast receiver"
        system "#{RUBOTO_CMD} _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
      end
      # FIXME end

      update_app
    end
    run_app_tests
  end

  def test_broadcast_receiver_updated_twice
    Dir.chdir APP_DIR do

      # FIXME(uwe): Remove check when we stop supporting updating from ruboto_core (Ruboto before version 0.5.2 2011-12-24)
      if Gem::Version.new(@old_ruboto_version) >= Gem::Version.new('0.5.2')
        puts "Adding a broadcast receiver"
        system "#{RUBOTO_CMD} _#{@old_ruboto_version}_ gen class BroadcastReceiver --name DummyReceiver"
      end
      # FIXME end

      update_app
      update_app
    end
    run_app_tests
  end

end
