require 'ruboto/base'
require 'ruboto/package'

#######################################################
#
# ruboto/activity.rb
#
# Basic activity set up.
#
#######################################################

#
# Context
#
module Ruboto
  module Context
    def start_ruboto_dialog(class_name = nil, options = nil, &block)
      if options.nil?
        if class_name.is_a?(Hash)
          options = class_name
          class_name = nil
        else
          options = {}
        end
      end

      unless options.key?(:java_class)
        java_import 'org.ruboto.RubotoDialog'
        options[:java_class] = RubotoDialog
      end

      options[:theme] = android.R.style::Theme_Dialog unless options.key?(:theme)

      start_ruboto_activity(class_name, options, &block)
    end

    def start_ruboto_activity(class_name = nil, options = nil, &block)
      if options.nil?
        if class_name.is_a?(Hash)
          options = class_name
          class_name = nil
        else
          options = {}
        end
      end

      # FIXME(uwe):  Deprecated.  Remove june 2014.
      if options[:class_name]
        puts "\nDEPRECATION: The ':class_name' option is deprecated.  Put the class name in the first argument instead."
      end

      java_class = options.delete(:java_class) || RubotoActivity
      theme = options.delete(:theme)

      # FIXME(uwe):  Remove the use of the :class_name option in june 2014
      class_name_option = options.delete(:class_name)
      class_name ||= class_name_option
      # EMXIF

      script_name = options.delete(:script)
      extras = options.delete(:extras)
      flags = options.delete(:flags)

      raise "Unknown options: #{options}" unless options.empty?

      if class_name.nil?
        if block_given?
          src_desc = source_descriptor(block)
          class_name =
              "#{java_class.name.split('::').last}_#{src_desc[0].split('/').last.gsub(/[.-]+/, '_')}_#{src_desc[1]}"
        else
          class_name = java_class.name.split('::').last
        end
      end

      class_name = class_name.to_s

      if Object.const_defined?(class_name)
        Object.const_get(class_name).class_eval(&block) if block_given?
      else
        Object.const_set(class_name, Class.new(&block))
      end
      i = android.content.Intent.new
      i.setClass self, java_class.java_class
      i.add_flags(flags) if flags
      i.putExtra(Ruboto::THEME_KEY, theme) if theme
      i.putExtra(Ruboto::CLASS_NAME_KEY, class_name) if class_name
      i.putExtra(Ruboto::SCRIPT_NAME_KEY, script_name) if script_name
      extras.each { |k, v| i.putExtra(k.to_s, v) } if extras
      startActivity i
      self
    end

    private

    def source_descriptor(src_proc)
      if (md = /^#<Proc:0x[0-9A-Fa-f-]+@(.+):(\d+)(?: \(lambda\))?>$/.match(src_proc.inspect))
        filename, line = md.captures
        return filename, line.to_i
      end
    end

  end

end

java_import 'android.content.Context'
Context.class_eval do
  include Ruboto::Context
end

#
# Basic Activity Setup
#

module Ruboto
  module Activity
    def method_missing(method, *args, &block)
      return @ruboto_java_instance.send(method, *args, &block) if @ruboto_java_instance && @ruboto_java_instance.respond_to?(method)
      super
    end
  end
end

def ruboto_configure_activity(klass)
  klass.class_eval do
    include Ruboto::Activity
  end
end

java_import 'android.app.Activity'
java_import 'org.ruboto.RubotoActivity'
ruboto_configure_activity(RubotoActivity)
