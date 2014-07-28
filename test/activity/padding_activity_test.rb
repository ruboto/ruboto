activity Java::org.ruboto.test_app.PaddingActivity

setup do |activity|
  start = Time.now
  loop do
    @layout = activity.findViewById(41)
    @text_view = activity.findViewById(42)
    break if (@layout && @text_view) || Time.now - start > 60
    sleep 0.5
  end
  assert @layout
  assert @text_view
end

test('padding is set') do |activity|
  assert_equal 40, @layout.padding_bottom
  assert_equal 30, @layout.padding_end
  assert_equal 10, @layout.padding_left
  assert_equal 30, @layout.padding_right
  assert_equal 10, @layout.padding_start
  assert_equal 20, @layout.padding_top

  assert_equal 8, @text_view.padding_bottom
  assert_equal 4, @text_view.padding_end
  assert_equal 1, @text_view.padding_left
  assert_equal 4, @text_view.padding_right
  assert_equal 1, @text_view.padding_start
  assert_equal 2, @text_view.padding_top
end
