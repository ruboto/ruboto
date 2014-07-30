activity org.ruboto.test_app.ConstantsActivity

setup do |activity|
  start = Time.now
  loop do
    break if activity.findViewById(42)
    fail 'Text view not found.' if (Time.now - start > 60)
    sleep 0.5
  end
end

test('R inner class constants') do |activity|
  layout = activity.findViewById(android.R.id.content).get_child_at(0)
  layout.child_count.times do |n|
    child = layout.get_child_at(n)
    assert_equal child.tag, child.text, child.hint
  end
end
