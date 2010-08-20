task :default => :gem

task :gem do
  `gem build ruboto-core.gemspec`
end

task :release do
  `gem push ruboto-core-0.0.1.gem`
end

require 'erb'

def unprefixed_class(class_name)
  /\.([^\.]+)\z/.match(class_name)[1]
end

# active_support/inflector.rb
def underscore(camel_cased_word)
  camel_cased_word.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
end

def transform_return_type(type)
  if type.include?(".")
    return type
  elsif type == "int"
    return "Integer"
  else
    return type.capitalize
  end
end

task :generate_java_classes do
  all_callbacks = eval(IO.read("assets/lib/java_class_gen/interfaces.txt"))

  @starting_methods = {"BroadcastReceiver" => "onReceive"}
  @starting_methods.default = "onCreate"

  all_callbacks.each do |full_class, method_hash|
    @class = unprefixed_class full_class
    @callbacks = method_hash
    @full_class = full_class
    @first_method = @starting_methods[@class]


    ##############################################################################################
    #
    #   This code resolves any issues with the generated callbacks.
    #
    #   1) Remove callbacks that are hard coded in RubotoActivity.erb:
    #

    if @class == "Activity"
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
        "onSizeChanged" => {"args" => ["android.view.View", "int", "int", "int", "int"]}
      }
    end
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

        @implements << v["interface"] if v["interface"] != full_class and
          v["interface"] != @class and
          v["interface"] != "none" and
          not @implements.include?(v["interface"])

        unless v["constant"]
          constant = v["method"].gsub(/[A-Z]/) {|i| "_#{i}"}.upcase
          constant = constant[3..-1] if constant[0..2] == "ON_"
          v["constant"] = "CB_#{constant}"
        end
        @constants << v["constant"] unless @constants.include?(v["constant"]) || v["method"] == @first_method

        v["args"] = (v["args"] || [])
        v["args_with_types"], v["args_alone"] = [], []
        v["args"].each_with_index {|arg_type, i| v["args_with_types"] << "#{arg_type.gsub("$", ".")} arg#{i}"; v["args_alone"] << "arg#{i}"}
        v["args_with_types"] = v["args_with_types"].join(", ")
      end
    end
    ##############################################################################################


    File.open("assets/src/Inheriting#{@class}.java", "w") do |file|
      file.write ERB.new(IO.read("assets/lib/java_class_gen/InheritingClass.java.erb"), 0, "%").result
    end

    File.open("assets/src/org/ruboto/Ruboto#{@class}.java", "w") do |file|
      file.write ERB.new(IO.read("assets/lib/java_class_gen/RubotoClass.java.erb"), 0, "%").result
    end
  end
end

