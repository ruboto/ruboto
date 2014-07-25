activity Java::org.ruboto.test_app.SpinnerActivity

class Java::AndroidWidget::ArrayAdapter
  field_reader :mResource, :mDropDownResource, :mFieldId
end

setup do |activity|
  start = Time.now
  loop do
    @text_view = activity.findViewById(69)
    break if @text_view || (Time.now - start > 60)
    sleep 1
  end
  assert @text_view
end

test('default', :ui => false) do |activity|
  assert_spinner_selection(activity, 42, 'List Spinner')
end

test('plain', :ui => false) do |activity|
  assert_spinner_selection(activity, 43, 'Plain Item')
end

test('adapter', :ui => false) do |activity|
  assert_spinner_selection(activity, 44, 'Adapter Item')
end

test('list', :ui => false) do |activity|
  assert_spinner_selection(activity, 45, 'List Item')
end

test('list spinner view resources') do |activity|
  activity.run_on_ui_thread do
    spinner = activity.findViewById(45)
    assert_equal android.R::layout::simple_spinner_item, spinner.adapter.mResource
    assert_equal android.R::layout::simple_spinner_item, spinner.adapter.mDropDownResource
    assert_equal 0, spinner.adapter.mFieldId

    spinner = activity.findViewById(46)
    assert_equal android.R::layout::simple_spinner_dropdown_item, spinner.adapter.mResource
    assert_equal android.R::layout::simple_spinner_dropdown_item, spinner.adapter.mDropDownResource
    assert_equal 0, spinner.adapter.mFieldId

    spinner = activity.findViewById(47)
    assert_equal android.R::layout::simple_spinner_dropdown_item, spinner.adapter.mResource
    assert_equal android.R::layout::simple_spinner_item, spinner.adapter.mDropDownResource
    assert_equal 0, spinner.adapter.mFieldId
  end
end

def assert_spinner_selection(activity, spinner_id, expected_text)
  activity.run_on_ui_thread do
    activity.findViewById(spinner_id).setSelection(1, true)
  end
  start_time = Time.now
  text = nil
  loop do
    activity.run_on_ui_thread { text = @text_view.text }
    break if text == expected_text || (Time.now - start_time) > 4
    sleep 0.1
  end
  activity.run_on_ui_thread { assert_equal expected_text, text }
end

