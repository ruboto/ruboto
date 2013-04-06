activity Java::org.ruboto.test_app.ViewConstantsActivity
java_import 'android.view.ViewGroup'
java_import 'android.view.Gravity'
java_import 'android.os.Build'

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(42)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

def view_constant(const)
  View.convert_constant(const.downcase.to_sym)
end

test('LayoutParams Constants') do |activity|
  ViewGroup::LayoutParams.constants.each do |const|
    assert_equal ViewGroup::LayoutParams.const_get(const), view_constant(const)
  end
end

test('Gravity Constants') do |activity|
  Gravity.constants.each do |const|
    assert_equal Gravity.const_get(const), view_constant(const)
  end
end
