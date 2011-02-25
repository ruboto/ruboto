puts '*' * 80
puts "INSIDE THE RUBY TEST"
puts '*' * 80

require 'java'
# require 'ruboto.rb'


# import_java 'android.test.ActivityInstrumentationTestCase2'
import_java 'android.widget.TextView'

@mActivity      = $test.activity
@resourceString = "What hath Matz wrought?";

start           = Java::java.lang.System.currentTimeMillis();

while @mView.nil?
  if (Java::java.lang.System.currentTimeMillis() - start > 60000) then
    break
  end
  Java::java.lang.Thread.sleep(1000);
  @mView = mActivity.findViewById(42);
end

# assertNotNull(@mView);
raise "@mView" unless @mView

# assertEquals(@resourceString, @mView.getText());
raise "@resourceString, @mView.getText() do not match" unless @resourceString == @mView.getText()

puts '*' * 80
puts "COMPLETED THE RUBY TEST"
puts '*' * 80
