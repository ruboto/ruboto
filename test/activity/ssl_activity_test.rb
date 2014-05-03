activity org.ruboto.test_app.SslActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('load net/https', :ui => false) do |activity|
  start = Time.now
  expected = 'net/https loaded OK!'
  result = nil
  loop do
    activity.run_on_ui_thread { result = activity.find_view_by_id(42).text.to_s }
    break if result == expected || (Time.now - start > 120)
    sleep 5
  end
  assert_equal expected, result
end
