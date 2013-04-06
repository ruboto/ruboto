activity org.ruboto.test_app.StartupExceptionActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('super called correctly') do |activity|
  assert_equal 'Startup OK', activity.find_view_by_id(42).text.to_s
end
