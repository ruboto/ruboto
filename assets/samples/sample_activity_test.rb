activity Java::THE_PACKAGE.SampleActivity

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
  assert_equal 'What hath Matz wrought?', @text_view.text
end

test('button changes text') do |activity|
  button = activity.findViewById(43)
  button.performClick
  assert_equal 'What hath Matz wrought!', @text_view.text
end
