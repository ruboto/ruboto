activity org.ruboto.test_app.DialogFragmentActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    wait_for_idle_sync
    fragment = activity.fragment_manager.findFragmentByTag('example_dialog')
    @fragment_text = fragment.view.findViewById(43) if fragment
    break if (@text_view && @fragment_text) || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view && @fragment_text
end

test 'start fragment', :ui => false do |activity|
  assert_equal 'Dialog Fragment Test', @text_view.text.to_s
  assert_equal 'Ruboto does fragments!', @fragment_text.text.to_s
end
