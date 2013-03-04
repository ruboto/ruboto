activity org.ruboto.test_app.DirAndFileActivity

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
  assert_matches %r{jar:file:/data/app/org.ruboto.test_app-[12].apk!/dir_and_file_activity.rb},
                 activity.find_view_by_id(42).text.to_s
  assert_matches %r{jar:file:/data/app/org.ruboto.test_app-[12].apk!},
                 activity.find_view_by_id(43).text.to_s
  assert_matches %r{file:/data/app/org.ruboto.test_app-[12].apk!/AndroidManifest.xml},
                 activity.find_view_by_id(44).text.to_s
end
