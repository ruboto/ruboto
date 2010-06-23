# callback_reflection.rb creates the interfaces.txt (JRuby can't do YAML with ruby 1.8, so it's just
# and inspect on the hash) on a device. Bring it off the device and put it in the callback_gen dir.
#
# Move this into a rake task later.
#

require 'erb'

task :generate_java_classes do

  @callbacks = eval(IO.read("lib/java_class_gen/interfaces.txt"))


  ##############################################################################################
  #
  #   This code resolves any issues with the generated callbacks.
  #   
  #   1) Remove callbacks that are hard coded in RubotoActivity.erb:
  #
  @callbacks["android.app.Activity"].delete("onCreate")
  @callbacks["android.view.View$OnCreateContextMenuListener"].delete("onCreateContextMenu")
  #
  #   2) Remove callbacks that are causing a problem
  #
  @callbacks["android.app.Activity"].delete("onRetainNonConfigurationChildInstances")
  #
  #   3) Override the callback constant for a few key callbacks
  #
  @callbacks["android.app.Activity"]["onMenuItemSelected"]["constant"] = "CB_CREATE_OPTIONS_MENU"
  @callbacks["android.app.Activity"]["onContextItemSelected"]["constant"] = "CB_CREATE_CONTEXT_MENU"
  #
  #   4) Create a unique name for callbacks that have duplicate names
  #    
  @callbacks["android.content.DialogInterface$OnClickListener"]["onClick"]["ruby_method"] = "on_dialog_click"
  @callbacks["android.content.DialogInterface$OnClickListener"]["onClick"]["constant"] = "CB_DIALOG_CLICK"
  @callbacks["android.content.DialogInterface$OnKeyListener"]["onKey"]["ruby_method"] = "on_dialog_key"
  @callbacks["android.content.DialogInterface$OnKeyListener"]["onKey"]["constant"] = "CB_DIALOG_KEY"
  @callbacks["android.content.DialogInterface$OnMultiChoiceClickListener"]["onClick"]["ruby_method"] = "on_dialog_multi_choice_click"
  @callbacks["android.content.DialogInterface$OnMultiChoiceClickListener"]["onClick"]["constant"] = "CB_DIALOG_MULTI_CHOICE_CLICK"
  #
  #   5) Report any duplicate name callbacks not handled
  #
  callbacks = {}
  @callbacks.each do |interface,i_info|
    i_info.each do |method,v|
      if callbacks[method] and not v["ruby_method"]
        puts "#{method} in #{interface} and #{callbacks[method]}"
      else
        callbacks[v["ruby_method"] || method] = interface
      end
    end
  end
  #
  #   6) Create a few new special case callbacks
  #
  @callbacks["none"] = {
    "onDraw" => {"args" => ["android.view.View", "android.graphics.Canvas"]}, 
    "onSizeChanged" => {"args" => ["RubotoView", "int", "int", "int", "int"]}
  }
  #
  ##############################################################################################
  #
  #   This code takes the callbacks hash (read out of the interfaces.txt file) and prepares
  #   it for use in the code below.
  #
  @implements = []
  @constants = []
  @callbacks.each do |interface,i_info|
    i_info.each do |method,v|
      v["interface"] = interface.gsub("$", ".")
      v["interface"] = "Activity" if v["interface"] == "android.app.Activity" 
      v["method"] = method
      v["return_type"] = (v["return_type"] || "void").gsub("$", ".")
      v["interface_method"] = v["interface_method"] || v["method"]
      v["ruby_method"] = v["ruby_method"] || v["method"].gsub(/[A-Z]/) {|i| "_#{i.downcase}"} 

      @implements << v["interface"] if v["interface"] != "Activity" and 
        v["interface"] != "none" and 
        not @implements.include?(v["interface"])

      unless v["constant"]
        constant = v["method"].gsub(/[A-Z]/) {|i| "_#{i}"}.upcase
        constant = constant[3..-1] if constant[0..2] == "ON_"
        v["constant"] = "CB_#{constant}"
      end
      @constants << v["constant"] unless @constants.include?(v["constant"])

      v["args"] = (v["args"] || [])
      v["args_with_types"], v["args_alone"] = [], []
      v["args"].each_with_index {|arg_type, i| v["args_with_types"] << "#{arg_type.gsub("$", ".")} arg#{i}"; v["args_alone"] << "arg#{i}"} 
      v["args_with_types"] = v["args_with_types"].join(", ")
    end
  end
  ##############################################################################################


  File.open("src/org/ruboto/embedded/RubotoActivity.java", "w") do |file|
    file.write ERB.new(IO.read("callback_gen/RubotoActivity.erb"), 0, "%").result
  end
end
