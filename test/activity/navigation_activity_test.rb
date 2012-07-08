activity Java::org.ruboto.test_app.ImageButtonActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('button changes text') do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
  activity.findViewById(43).performClick
  assert_equal "What hath Matz wrought!", @text_view.text
end
