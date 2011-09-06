activity org.ruboto.test_app.StackActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('stack depth is 44 or less') do |activity|
  assert_less_than_or_equal 44, activity.find_view_by_id(42).text.to_i
  assert_less_than_or_equal 68, activity.find_view_by_id(43).text.to_i
  assert_less_than_or_equal 77, activity.find_view_by_id(44).text.to_i
  assert_less_than_or_equal 96, activity.find_view_by_id(45).text.to_i
end
