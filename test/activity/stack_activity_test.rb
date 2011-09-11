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
  os_offset = {13 => 1}[android.os.Build::VERSION::SDK_INT].to_i
  jruby_offset = {'1.5.6' => -1}[org.jruby.runtime.Constants::VERSION].to_i
  version_message ="ANDROID: #{android.os.Build::VERSION::SDK_INT}, JRuby: #{org.jruby.runtime.Constants::VERSION}"
  assert_equal 44 + os_offset + jruby_offset * 2, activity.find_view_by_id(42).text.to_i, version_message
  assert_equal 68 + os_offset + jruby_offset * 5, activity.find_view_by_id(43).text.to_i, version_message
  assert_equal 77 + os_offset + jruby_offset * 6, activity.find_view_by_id(44).text.to_i, version_message
  assert_equal 96 + os_offset + jruby_offset * 8, activity.find_view_by_id(45).text.to_i, version_message
end
