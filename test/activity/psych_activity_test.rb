# TODO(uwe): Remove check when we stop supporting jruby-jars 1.5.6
if JRUBY_VERSION != '1.5.6'
  activity org.ruboto.test_app.PsychActivity

  setup do |activity|
    start = Time.now
    loop do
      @text_view = activity.findViewById(42)
      break if @text_view || (Time.now - start > 60)
      sleep 1
    end
    assert @text_view
  end

  test('psych_encode_decode') do |activity|
    assert_equal 'foo', activity.find_view_by_id(42).text.to_s
    #assert_equal "--- foo\n...\n", activity.find_view_by_id(43).text.to_s
  end
end
