activity org.ruboto.test_app.RssActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @list_view = activity.findViewById(43)
    break if (@text_view && @list_view) || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view && @list_view
end

test('fetch rss feed', ui: false) do |activity|
  start = Time.now
  loop do
    break if activity.findViewById(42).text.to_s == 'List updated'
    break if Time.now - start > 90
    sleep 0.5
  end
  assert_equal 'List updated', activity.findViewById(42).text.to_s
  assert_equal [],activity.findViewById(43).adapter.list.to_a
end
