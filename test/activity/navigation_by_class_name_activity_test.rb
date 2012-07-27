activity Java::org.ruboto.test_app.NavigationByClassNameActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.find_view_by_id(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('button starts next activity', :ui => false) do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  activity.run_on_ui_thread{activity.find_view_by_id(43).perform_click}
  current_activity = wait_for_monitor_with_timeout(monitor, 5000)
  assert current_activity
end

test('button starts inline activity', :ui => false) do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
  monitor = add_monitor('org.ruboto.RubotoActivity', nil, false)
  activity.run_on_ui_thread{activity.find_view_by_id(44).perform_click}
  current_activity = wait_for_monitor_with_timeout(monitor, 5000)
  assert current_activity
  start = Time.now
  loop do
    @text_view = current_activity.find_view_by_id(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
  assert_equal 'This is an inline activity.', @text_view.text
end
