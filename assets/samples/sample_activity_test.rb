require 'java'

$test.activity Java::THE_PACKAGE.SampleActivity

$test.test('test_generated_code') do |activity|
  # TODO(uwe):  Move this to $test.setup do
  # TODO(uwe):  end
  start = Time.now
  loop do
    @view = activity.findViewById(42);
    break if @view || (Time.now - start > 60)
    sleep 1
  end

# assert_not_nil @view
  raise "@view expected to be not nil" unless @view

# assert_equal resourceString, @view.text
  raise "resourceString and @view.getText() do not match" unless "What hath Matz wrought?" == @view.getText()
end

#$suite.addTest {
#  # Test succeeded
#}
#$suite.addTest {
#  raise 'test failed'
#}
