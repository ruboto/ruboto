activity Java::org.ruboto.test_app.OptionMenuActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('initial setup') do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
end

test('option_menu changes text') do |activity|
  activity.window.performPanelIdentifierAction(android.view.Window::FEATURE_OPTIONS_PANEL, 0, 0)
  assert_equal "What hath Matz wrought!", @text_view.text
end
