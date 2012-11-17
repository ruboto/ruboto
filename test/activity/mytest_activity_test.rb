activity org.ruboto.test_app.MytestActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

def button_activity_text button_id, activity, expected_text_id, expected_text_string
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(button_id).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
  ensure
    removeMonitor(monitor)
  end
  puts "new activity: #{current_activity.inspect}"
  assert current_activity
   assert current_activity.is_a? Java::OrgRuboto::RubotoActivity
  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(expected_text_id)
    break if @text_view || (Time.now - start > 10)
    puts 'wait for text'
    sleep 1
  end
  assert @text_view
  assert_equal expected_text_string, @text_view.text
  current_activity.run_on_ui_thread { current_activity.finish }
  # FIXME(uwe):  Replace sleep with proper monitor
  sleep 3
end

test("infile activity starts once", :ui => false) do |activity|
  button_activity_text 48, activity, 42, 'This is an infile activity.'
end

test("infile activity starts again", :ui => false) do |activity|
  button_activity_text 48, activity, 42, 'This is an infile activity.'
end

test("otherfile activity starts once", :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is an otherfile activity.'
end

test("otherfile activity starts again", :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is an otherfile activity.'
end
