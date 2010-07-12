# callback_reflection.rb creates the interfaces.txt (JRuby can't do YAML with ruby 1.8, so it's just
# and inspect on the hash) on a device. Bring it off the device and put it in the callback_gen dir.
#
# Move this into a rake task later.
#

require 'erb'

def unprefixed_class(class_name)
  /\.([^\.]+)\z/.match(class_name)[1]
end

task :generate_java_classes do
  all_callbacks = eval(IO.read("lib/java_class_gen/interfaces.txt"))
  all_callbacks.each do |full_class, method_hash|
    @class = unprefixed_class full_class
    @callbacks = method_hash


    ##############################################################################################
    #
    #   This code resolves any issues with the generated callbacks.
    #   
    #   1) Remove callbacks that are hard coded in RubotoActivity.erb:
    #
    @callbacks[full_class].delete("onCreate")

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
        @constants << v["constant"] unless @constants.include?(v["constant"])

        v["args"] = (v["args"] || [])
        v["args_with_types"], v["args_alone"] = [], []
        v["args"].each_with_index {|arg_type, i| v["args_with_types"] << "#{arg_type.gsub("$", ".")} arg#{i}"; v["args_alone"] << "arg#{i}"} 
        v["args_with_types"] = v["args_with_types"].join(", ")
      end
    end
    ##############################################################################################


    File.open("src/org/ruboto/Ruboto#{@class}.java", "w") do |file|
      file.write ERB.new(IO.read("lib/java_class_gen/RubotoClass.java.erb"), 0, "%").result
    end
  end
end

#task :default => :generate_java_classes

raise "Needs JRuby 1.5" unless RUBY_PLATFORM =~ /java/
require 'ant'
require 'rake/clean'
require 'rexml/document'

generated_libs     = 'generated_libs'
stdlib             = 'libs/jruby-stdlib.jar'
jruby_jar          = 'libs/jruby.jar'
stdlib_precompiled = File.join(generated_libs, 'jruby-stdlib-precompiled.jar')
jruby_ruboto_jar   = File.join(generated_libs, 'jruby-ruboto.jar')
ant.property :name=>'external.libs.dir', :value => generated_libs
dirs = ['tmp/ruby', 'tmp/precompiled', generated_libs]
dirs.each { |d| directory d }

CLEAN.include('tmp', 'bin', generated_libs)

ant_import

file stdlib_precompiled => :compile_stdlib
file jruby_ruboto_jar => generated_libs do
  ant.zip(:destfile=>jruby_ruboto_jar) do
    zipfileset(:src=>jruby_jar) do
      exclude(:name=>'jni/**')
    end
  end
end

desc "precompile ruby stdlib"
task :compile_stdlib => [:clean, *dirs] do
  ant.unzip(:src=>stdlib, :dest=>'tmp/ruby')
  Dir.chdir('tmp/ruby') { sh "jrubyc . -t ../precompiled" }
  ant.zip(:destfile=>stdlib_precompiled, :basedir=>'tmp/precompiled')
end

task :generate_libs => [generated_libs, jruby_ruboto_jar] do
  cp stdlib, generated_libs
end

task :debug   => :generate_libs
task :release => :generate_libs

task :default => :debug

task :tag => :release do
  unless `git branch` =~ /^\* master$/
    puts "You must be on the master branch to release!"
    exit!
  end
  sh "git commit --allow-empty -a -m 'Release #{version}'"
  sh "git tag #{version}"
  sh "git push origin master --tags"
  #sh "gem push pkg/#{name}-#{version}.gem"
end

def manifest
  @manifest ||= REXML::Document.new(File.read('AndroidManifest.xml'))
end

def strings(name)
  @strings ||= REXML::Document.new(File.read('res/values/strings.xml'))
  value = @strings.elements["//string[@name='#{name.to_s}']"] or raise "string '#{name}' not found in strings.xml"
  value.text
end

def package() manifest.root.attribute('package') end
def version() strings :version_name end
def app_name()  strings :app_name end
