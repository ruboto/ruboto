activity Java::org.ruboto.test_app.ImageButtonAndButtonActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.find_view_by_id 42
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('initial setup') do |activity|
  assert_equal "What hath Matz wrought?", @text_view.text
end

test('button changes text') do |activity|
  button = activity.find_view_by_id 44
  button.perform_click
  assert_equal 'Button pressed', @text_view.text
end

test('image button changes text') do |activity|
  image_button = activity.find_view_by_id 43
  image_button.perform_click
  assert_equal 'Image button pressed', @text_view.text
end
