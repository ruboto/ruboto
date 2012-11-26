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
  #::NavigationTargetActivity = ::RubyFileActivity
  #Object.const_set(:NavigationTargetActivity, RubyFileActivity)
  #Kernel.const_set(:NavigationTargetActivity, RubyFileActivity)
  button_activity_text 43, activity, 42, 'This is the navigation target activity.',
                       'org.ruboto.test_app.NavigationTargetActivity'
end

test('button starts Java activity', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.test_app.NavigationTargetActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(43).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
    assert current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  ensure
    puts "Removing monitor"
    removeMonitor(monitor)
  end
end

test('button starts Ruby activity', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(44).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
    assert current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  ensure
    puts "Removing monitor"
    removeMonitor(monitor)
  end
end

test('button starts activity by script name', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(45).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
    assert current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  ensure
    puts "Removing monitor"
    removeMonitor(monitor)
  end
end

test('button starts inline activity', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(46).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
    assert current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  ensure
    puts "Removing monitor"
    removeMonitor(monitor)
  end

  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(42)
    break if (@text_view && @text_view.text == 'This is an inline activity.') || (Time.now - start > 10)
    puts 'wait for text'
    sleep 0.5
  end
  assert @text_view
  assert_equal 'This is an inline activity.', @text_view.text
end

test('button starts inline activity with options', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(47).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
    assert current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  ensure
    puts "Removing monitor"
    removeMonitor(monitor)
  end

  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(42)
    break if (@text_view && @text_view.text == 'This is an inline activity.') || (Time.now - start > 10)
    puts 'wait for text'
    sleep 0.5
  end
  assert @text_view
  assert_equal 'This is an inline activity.', @text_view.text
end

test('button starts infile class activity', :ui => false) do |activity|
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(48).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
  ensure
    removeMonitor(monitor)
  end
  puts "new activity: #{current_activity.inspect}"
  assert current_activity
  assert current_activity.is_a? Java::OrgRuboto::RubotoActivity
  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(42)
    break if @text_view || (Time.now - start > 10)
    puts 'wait for text'
    sleep 1
  end
  assert @text_view
  assert_equal 'This is an infile activity.', @text_view.text
  current_activity.run_on_ui_thread { current_activity.finish }
  # FIXME(uwe):  Replace sleep with proper monitor
  sleep 3
end


test("infile activity starts again", :ui => false) do |activity|
  button_activity_text 48, activity, 42, 'This is an infile activity.'
end

test("start ruby file activity", :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is a Ruby file activity.'
end

test("start ruby file activity again", :ui => false) do |activity|
  button_activity_text 49, activity, 42, 'This is a Ruby file activity.'
end

def button_activity_text button_id, activity, expected_text_id, expected_text_string,
    activity_class_name = 'org.ruboto.RubotoActivity'
  monitor = add_monitor(activity_class_name, nil, false)
  begin
    activity.run_on_ui_thread { activity.find_view_by_id(button_id).perform_click }
    current_activity = wait_for_monitor_with_timeout(monitor, 5000)
  ensure
    removeMonitor(monitor)
  end
  puts "new activity: #{current_activity.inspect}"
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
ensure
  if current_activity
    current_activity.run_on_ui_thread { current_activity.finish }
    # FIXME(uwe):  Replace sleep with proper monitor
    sleep 3
  end
end
