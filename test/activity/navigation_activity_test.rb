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

test('button starts Java activity', :ui => false) do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
  monitor = add_monitor('org.ruboto.test_app.NavigationActivity', nil, false)
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
  assert_equal "What hath Matz wrought?", @text_view.text
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
  assert_equal "What hath Matz wrought?", @text_view.text
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
  assert_equal "What hath Matz wrought?", @text_view.text
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
  assert_equal "What hath Matz wrought?", @text_view.text
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
  assert_equal "What hath Matz wrought?", @text_view.text
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
