activity org.ruboto.test_app.SslActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @response_view = activity.findViewById(43)
    break if (@text_view && @response_view)|| (Time.now - start > 60)
    sleep 1
  end
  assert @text_view && @response_view
end

test('load net/https', :ui => false) do |activity|
  start = Time.now
  expected = 'net/https loaded OK!'
  response_expected = '<title>Google</title>'
  result = response = nil
  loop do
    activity.run_on_ui_thread do
      result = @text_view.text.to_s
      response = @response_view.text.to_s
    end
    break if (result == expected && response == response_expected) ||
        (Time.now - start > 60)
    sleep 0.5
  end
  assert_equal expected, result
  assert_equal response_expected, response
end
