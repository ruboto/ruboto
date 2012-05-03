require File.expand_path("test_helper", File.dirname(__FILE__))
require 'fileutils'

class BroadcastReceiverTest < Test::Unit::TestCase
  SRC_DIR ="#{APP_DIR}/src"

  def setup
    generate_app
  end

  def teardown
    cleanup_app
  end

  def test_generated_broadcast_receiver
    action_name ='org.ruboto.example.click_broadcast'
    message = 'Broadcast received!'
    Dir.chdir APP_DIR do
      activity_filename = 'src/ruboto_test_app_activity.rb'
      activity_content = File.read(activity_filename)

      assert activity_content.sub!(/  def on_create\(bundle\)\n/, <<EOF)
  def on_create(bundle)
    @receiver = $package.ClickReceiver.new
    filter = android.content.IntentFilter.new('#{action_name}')
    Thread.start do
      begin
        android.os.Looper.prepare
        registerReceiver(@receiver, filter, nil, android.os.Handler.new)
        android.os.Looper.loop
      rescue
        puts "Exception starting receiver"
        puts $!.message
        puts $!.backtrace.join("\n")
      end
    end
EOF

      assert activity_content.sub!(/  @handle_click = proc do \|view\|\n.*?  end\n/m, <<EOF)
  @handle_click = proc do |view|
    intent = android.content.Intent.new
    intent.set_action '#{action_name}'
    send_broadcast(intent)
  end
EOF
      File.open(activity_filename, 'w') { |f| f << activity_content }

      system "#{RUBOTO_CMD} gen class BroadcastReceiver --name ClickReceiver"
      FileUtils.rm 'test/src/click_receiver_test.rb'
      receiver_filename = 'src/click_receiver.rb'
      receiver_content = File.read(receiver_filename)

      assert receiver_content.sub!(/  def on_receive\(context, intent\)\n.*?  end\n/m, <<EOF)
  def on_receive(context, intent)
    Log.d "RUBOTO TEST", "Changing UI text"
    context.run_on_ui_thread{$activity.find_view_by_id(42).text = '#{message}'}
    Log.d "RUBOTO TEST", "UI text changed OK!"
  rescue
    Log.e "RUBOTO TEST", "Exception changing UI text: \#{$!.message}"
    Log.e "RUBOTO TEST", $!.message
    Log.e "RUBOTO TEST", $!.backtrace.join("\n")
  end
EOF
      File.open(receiver_filename, 'w') { |f| f << receiver_content }

      test_filename = 'test/src/ruboto_test_app_activity_test.rb'
      test_content = File.read(test_filename)

      assert test_content.sub!(/'button changes text'/, "'button changes text', :ui => false")
      assert test_content.sub!(/  button.performClick/, <<EOF)
  clicked_at = nil
  activity.run_on_ui_thread do
    button.performClick
    clicked_at = Time.now
  end

  sleep 0.1 until clicked_at && (@text_view.text == '#{message}' || (Time.now - clicked_at) > 10)
EOF
      assert test_content.sub!(/What hath Matz wrought!/, message)
      File.open(test_filename, 'w') { |f| f << test_content }
    end

    run_app_tests
  end

end
