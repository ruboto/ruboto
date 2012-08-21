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

# ANDROID: 15, PLATFORM: 0.4.8.dev,  JRuby: 1.7.0.preview2 '[44, 68, 77, 93]' expected, but got '[44, 67, 76, 92]'
# ANDROID: 10, PLATFORM: STANDALONE, JRuby: 1.7.0.preview2 '[43, 67, 76, 92]' expected, but got '[43, 66, 75, 91]'
# ANDROID: 15, PLATFORM: STANDALONE, JRuby: 1.7.0.preview2 '[44, 68, 77, 93]' expected, but got '[44, 67, 76, 92]'

test('stack depth') do |activity|
  os_offset = {13 => 1, 15 => 1, 16 => 1}[android.os.Build::VERSION::SDK_INT].to_i
  if org.ruboto.JRubyAdapter.uses_platform_apk?
    jruby_offset = {
        '0.4.7' => [0, -1, -1, -1],
        '0.4.8.dev' => [0, -2, -2, -2],
    }[org.ruboto.JRubyAdapter.platform_version_name] || [0, 0, 0, 0]
  else # STANDALONE
    jruby_offset = {
        '1.7.0.dev' => [1, 1, 1, 1],
        '1.7.0.preview1' => [0, -1, -1, -1],
        '1.7.0.preview2' => [0, -2, -2, -2],
    }[org.jruby.runtime.Constants::VERSION] || [0, 0, 0, 0]
  end
  version_message ="ANDROID: #{android.os.Build::VERSION::SDK_INT}, PLATFORM: #{org.ruboto.JRubyAdapter.uses_platform_apk ? org.ruboto.JRubyAdapter.platform_version_name : 'STANDALONE'}, JRuby: #{org.jruby.runtime.Constants::VERSION}"
  expected = [43 + os_offset + jruby_offset[0],
              68 + os_offset + jruby_offset[1],
              77 + os_offset + jruby_offset[2],
              93 + os_offset + jruby_offset[3]]
  actual = [activity.find_view_by_id(42).text.to_i,
            activity.find_view_by_id(43).text.to_i,
            activity.find_view_by_id(44).text.to_i,
            activity.find_view_by_id(45).text.to_i]
  assert_equal expected, actual, version_message
  puts "handle stack: #{version_message} #{actual.inspect}"
end
