activity Java::org.ruboto.test_app.GenerateActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    @list_view = activity.findViewById(43)
    break if (@text_view && @list_view) || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
  assert @list_view
end

test("activity starts") do |activity|
  assert true
end
