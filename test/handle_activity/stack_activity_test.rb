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

test('stack depth') do |activity|
  os_offset = {13 => 1, 15 => 1, 16 => 1}[android.os.Build::VERSION::SDK_INT].to_i
  if org.ruboto.Script.uses_platform_apk?
    jruby_offset = {
        '0.4.7' => [0, 0, 0, 0],
        '0.4.8.dev' => [0, 0, 0, 0],
    }[org.ruboto.Script.platform_version_name] || [0, 0, 0, 0]
  else
    jruby_offset = {
        '1.7.0.dev' => [1, 1, 1, 1],
        '1.7.0.preview1' => [0, -1, -1, -1],
        '1.7.0.preview2.dev' => [0, -1, -1, -1],
    }[org.jruby.runtime.Constants::VERSION] || [0, 0, 0, 0]
  end
  version_message ="ANDROID: #{android.os.Build::VERSION::SDK_INT}, PLATFORM: #{org.ruboto.Script.uses_platform_apk ? org.ruboto.Script.platform_version_name : 'STANDALONE'}, JRuby: #{org.jruby.runtime.Constants::VERSION}"
  assert_equal 43 + os_offset + jruby_offset[0], activity.find_view_by_id(42).text.to_i, version_message
  assert_equal 67 + os_offset + jruby_offset[1], activity.find_view_by_id(43).text.to_i, version_message
  assert_equal 76 + os_offset + jruby_offset[2], activity.find_view_by_id(44).text.to_i, version_message
  assert_equal 92 + os_offset + jruby_offset[3], activity.find_view_by_id(45).text.to_i, version_message
end
