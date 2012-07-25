activity Java::org.ruboto.test_app.MarginsActivity

setup do |activity|
  start = Time.now
  loop do
    @text_view_margins = activity.findViewById(42)
    @text_view_layout = activity.findViewById(43)
    @text_view_fieldset = activity.findViewById(44)
    break if @text_view_margins || @text_view_layout || @text_view_fieldset || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view_margins
  assert @text_view_layout
  assert @text_view_fieldset
end

def left_margin(view)
  view.get_layout_params.leftMargin
end

%w(margins layout fieldset).each do |view_type|
  test("margins are set through #{view_type}") do |activity|  
    assert_equal 100, left_margin(instance_variable_get("@text_view_#{view_type}"))
  end
end