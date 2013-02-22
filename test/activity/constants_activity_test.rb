activity org.ruboto.test_app.ConstantsActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('__FILE__ is set OK') do |activity|
  assert_matches %r{jar:file:/data/app/org.ruboto.test_app-[12].apk!/constants_activity.rb},
               activity.find_view_by_id(42).text.to_s
end
