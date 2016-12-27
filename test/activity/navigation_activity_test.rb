activity Java::org.ruboto.test_app.NavigationActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.find_view_by_id(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('Java backed activity is reloaded if source already loaded', :ui => false) do |activity|
  require 'navigation_target_activity'
  button_activity_text 43, activity, 42, 'This is the navigation target activity.',
                       'org.ruboto.test_app.NavigationTargetActivity'
end

test('button starts Java activity', :ui => false) do |activity|
  button_activity_text 43, activity, 42, 'This is the navigation target activity.',
                       'org.ruboto.test_app.NavigationTargetActivity'
end

test('button starts Ruby activity', :ui => false) do |activity|
  button_activity_text 44, activity, 42, 'This is the navigation target activity.'
end

test('button starts activity by script name', :ui => false) do |activity|
  button_activity_text 45, activity, 42, 'This is the navigation target activity.'
end

test('button starts inline activity', :ui => false) do |activity|
  button_activity_text 46, activity, 42, 'This is an inline activity.'
end

test('button starts inline activity with options', :ui => false) do |activity|
  button_activity_text 47, activity, 42, 'This is an inline activity.'
end

test('button starts infile class activity', :ui => false) do |activity|
  button_activity_text 48, activity, 42, 'This is an infile activity.'
end

test('infile activity starts again', :ui => false) do |activity|
  button_activity_text 48, activity, 42, 'This is an infile activity.'
end

test('start ruby file activity', :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is a Ruby file activity.'
end

test('start ruby file activity again', :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is a Ruby file activity.'
end

test('start ruboto activity without config', :ui => false) do |activity|
  begin
    a = start_activity_by_button activity, 50
    assert_equal 'Ruboto Test App', a.title
  ensure
    if a
      finish_at = Time.now
      finished = false
      a.run_on_ui_thread { a.finish; finished = true }
      loop do
        break if finished || (Time.now - finish_at > 10)
        puts 'wait for finish'
        sleep 0.1
      end
    end
  end
end

test('start ruboto activity with class name', :ui => false) do |activity|
  button_activity_text 51, activity, 42, 'This is a Ruby file activity.'
end

test('start ruboto activity with extras', :ui => false) do |activity|
  button_activity_text 52, activity, 42, 'Started with string extra.'
end

def start_activity_by_button(activity, button_id, activity_class_name = 'org.ruboto.RubotoActivity')
  monitor = add_monitor(activity_class_name, nil, false)
  begin
    activity.run_on_ui_thread do
      btn = activity.find_view_by_id(button_id)
      btn.request_focus
      btn.perform_click
    end
    puts 'waitForIdleSync'
    waitForIdleSync
    puts 'wait_for_monitor_with_timeout'
    current_activity = monitor.wait_for_activity_with_timeout(10000)
    puts "current_activity: #{current_activity.inspect}"
  ensure
    removeMonitor(monitor)
  end
  puts "new activity: #{current_activity.inspect}"
  assert current_activity.is_a? Java::OrgRuboto::RubotoActivity
  current_activity
end

def button_activity_text(button_id, activity, expected_text_id, expected_text_string,
    activity_class_name = 'org.ruboto.RubotoActivity')
  puts "Start activity: #{expected_text_string}"
  current_activity = start_activity_by_button(activity, button_id, activity_class_name)
  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(expected_text_id)
    break if @text_view || (Time.now - start > 10)
    puts 'wait for text'
    sleep 1
  end
  assert @text_view
  assert_equal expected_text_string, @text_view.text
ensure
  if current_activity
    finish_at = Time.now
    finished = false
    current_activity.run_on_ui_thread { current_activity.finish; finished = true }
    loop do
      break if finished || (Time.now - finish_at > 10)
      puts 'wait for finish'
      sleep 0.1
    end
  end
end
