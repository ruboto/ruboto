require 'ruboto.rb'
require 'java'

ruboto_import_widgets :TextView

java_import 'android.util.Log'
Log.d "RUBOTO", "In start.rb"

$activity.start_ruboto_activity "$hello" do
  setTitle "Hello World"
  setup_content do
    text_view :text => "What hath God wrought?"
  end
end
