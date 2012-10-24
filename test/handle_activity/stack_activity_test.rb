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

# ANDROID: 15, PLATFORM: STANDALONE, JRuby: 1.6.7          '44697894' expected, but got '44687793'
# ANDROID: 15, PLATFORM: 0.4.8.dev,  JRuby: 1.7.0.preview2 '[44, 68, 77, 93]' expected, but got '[44, 67, 76, 92]'
# ANDROID: 10, PLATFORM: STANDALONE, JRuby: 1.7.0.preview2 '[43, 67, 76, 92]' expected, but got '[43, 66, 75, 91]'
# ANDROID: 15, PLATFORM: STANDALONE, JRuby: 1.7.0.preview2 '[44, 68, 77, 93]' expected, but got '[44, 67, 76, 92]'
# ANDROID: 15, PLATFORM: STANDALONE, JRuby: 1.7.0          '[44, 68, 77, 93]' expected, but got '[44, 67, 76, 92]'
test('stack depth') do |activity|
  os_offset = {13 => 1, 15 => 1, 16 => 1}[android.os.Build::VERSION::SDK_INT].to_i
  if org.ruboto.JRubyAdapter.uses_platform_apk?
    jruby_offset = {
        '0.4.7'     => [0, 0, 0, 0],
        '0.4.8.dev' => [0, -1, -1, -1],
        '0.4.8' => [0, -1, -1, -1],
        '0.4.9' => [0, -1, -1, -1],
    }[org.ruboto.JRubyAdapter.platform_version_name] || [0, 0, 0, 0]
  else # STANDALONE
    jruby_offset = {
        '1.7.0.dev' => [1, 0, 0, 0],
        '1.7.0.preview1' => [0, -1, -1, -1],
        '1.7.0.preview2' => [0, -1, -1, -1],
        '1.7.0' => [0, -1, -1, -1],
    }[org.jruby.runtime.Constants::VERSION] || [0, 0, 0, 0]
  end
  version_message ="ANDROID: #{android.os.Build::VERSION::SDK_INT}, PLATFORM: #{org.ruboto.JRubyAdapter.uses_platform_apk ? org.ruboto.JRubyAdapter.platform_version_name : 'STANDALONE'}, JRuby: #{org.jruby.runtime.Constants::VERSION}"
  expected = [43 + os_offset + jruby_offset[0],
              67 + os_offset + jruby_offset[1],
              76 + os_offset + jruby_offset[2],
              92 + os_offset + jruby_offset[3]]
  actual = [activity.find_view_by_id(42).text.to_i,
            activity.find_view_by_id(43).text.to_i,
            activity.find_view_by_id(44).text.to_i,
            activity.find_view_by_id(45).text.to_i]
  assert_equal expected, actual, version_message
  puts "handle stack: #{version_message} #{actual.inspect}"
end
