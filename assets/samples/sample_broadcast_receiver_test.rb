# Change this to the activity that will send the broadcast
activity Java::THE_PACKAGE.SampleActivity

# Change this to wait for the activity to be created
setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

# Change this to trigger the sending of broadcast intents
# and assert that the receiver behaves correctly.
test('broadcast changes title', :ui => false) do |activity|
  begin
    @receiver = $package.SampleBroadcastReceiver.new
    action = '__THE_PACKAGE__.SampleBroadcastReceiver.action'
    filter = android.content.IntentFilter.new(action)
    receiver_ready = false
    Thread.start do
      begin
        android.os.Looper.prepare
        activity.registerReceiver(@receiver, filter, nil, android.os.Handler.new)
        receiver_ready = true
        android.os.Looper.loop
      rescue
        puts "Exception starting receiver"
        puts $!.message
        puts $!.backtrace.join("\n")
      end
    end
    sleep 0.1 until receiver_ready
    intent = android.content.Intent.new
    intent.set_action action
    activity.send_broadcast(intent)
    bc_sent_at = Time.now

    message = 'Broadcast received!'
    sleep 0.1 until activity.title == message || (Time.now - bc_sent_at) > 10
    assert_equal message, activity.title
  ensure
    activity.unregister_receiver(@receiver) if @receiver
  end
end
