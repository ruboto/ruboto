require 'ruboto/util/code_formatting'
require 'ruboto/util/verify'
require 'ruboto/api'

module Ruboto
  module Util
    ###########################################################################
    #
    # XMLElement:
    #   Extends Hash to simulate a REXML::Element (but much faster) and provides
    #   information in the necessary format to generate Java code.
    #
    class XMLElement < Hash
      include Ruboto::Util::CodeFormatting
      include Ruboto::Util::Verify

      def root
        Ruboto::API.api
      end

      def name
        self["name"]
      end

      def attribute(name)
        self["values"][name]
      end

      def add_element(name, attributes)
        new_element = XMLElement.new
        new_element["name"] = name
        new_element["values"] = attributes

        self[name] = [] unless self[name]
        self[name] << new_element

        new_element
      end

      def get_elements(name)
        self[name] or []
      end

      def find_class_or_interface(klass, a_type)
        abort "ERROR: Can't parse package from #{klass}" unless klass.match(/([a-z.]+)\.([A-Z][A-Za-z.]+)/)

        package = self["package"].find{|i| i.attribute("name") == $1}
        abort "ERROR: Can't find package #{$1}" unless package
        if a_type == "either"
          package["class"].find{|i| i.attribute("name") == $2} or package["interface"].find{|i| i.attribute("name") == $2}
        else
          package[a_type].find{|i| i.attribute("name") == $2}
        end
      end

      def find_class(package_and_class)
        find_class_or_interface(package_and_class, "class")
      end

      def find_interface(package_and_interface)
        find_class_or_interface(package_and_interface, "interface")
      end

      def all_methods(method_base="all", method_include="", method_exclude="", implements="")
        # get all the methogs
        all_methods = get_elements("method")

        # establish the base set of methods
        working_methods = case method_base
        when "all" then
          all_methods
        when "none" then
          []
        when "abstract" then
          all_methods.select{|i| i.attribute("abstract") == "true"}
        when "on" then
          all_methods.select{|i| i.attribute("name").match(/^on[A-Z]/)}
        end

        # make sure to include requested methods
        include_methods = method_include.split(",") if method_include.is_a?(String)
        all_methods.each{|i| working_methods << i if include_methods.include?(i.attribute("name"))}

        # make sure to exclude rejected methods
        exclude_methods = method_exclude.split(",") if method_exclude.is_a?(String)
        working_methods = working_methods.select{|i| not exclude_methods.include?(i.attribute("name"))}

        # remove methods marked final
        working_methods = working_methods.select{|i| (not i.attribute("final")) or i.attribute("final") == "false"}

        # get additional methods from parent
        if name =="class" and attribute("extends")
          parent = root.find_class(attribute("extends"))
          parent_methods = parent.all_methods(method_base, method_include, method_exclude)
          working_signatures = working_methods.map(&:method_signature)
          working_methods += parent_methods.select{|i| not working_signatures.include?(i.method_signature)}
        end

        # get additional methods from interfaces
        if name =="class" and implements != ""
          implements.split(",").each do |i|
            interface = root.find_interface(i)
            abort("Unkown interface: #{i}") unless interface
            working_signatures = working_methods.map(&:method_signature)
            working_methods += interface.all_methods.select{|j| not working_signatures.include?(j.method_signature)}
          end
        end

        working_methods
      end

      def parameters
        get_elements("parameter").map {|p| [p.attribute("name"), p.attribute("type").gsub("&lt;", "<").gsub("&gt;", ">")]}
      end

      def method_signature
        "#{attribute("name")}(#{parameters.map{|i| i[1]}.join(',')})"
      end

      def constant_string
        "CB_" + attribute("name").gsub(/[A-Z]/) {|i| "_#{i}"}.upcase.gsub(/^ON_/, "")
      end

      def super_string
        if attribute("api_added") and
          attribute("api_added").to_i > verify_min_sdk.to_i and
          attribute("api_added").to_i <= verify_target_sdk.to_i
          nil
        elsif attribute("abstract") == "true"
          nil
        elsif name == "method"
          "super.#{attribute("name")}(#{parameters.map{|i| i[0]}.join(", ")});"
        elsif name == "constructor"
          "super(#{parameters.map{|i| i[0]}.join(", ")});"
        end
      end

      def default_return
        return nil unless attribute("return")
        case attribute("return")
        when "boolean" then "return false;"
        when "int"     then "return 0;"
        when "void"    then nil
        else                "return null;"
        end
      end

      def super_return
        rv = super_string
        return rv unless attribute("return")
        rv ? "return #{rv}" : default_return
      end

      def ruby_call(on_ruby_instance = false, camelize = false)
        params = parameters
        args = ""
        if params.size > 1
          args = ", new Object[]{" + params.map{|i| i[0]}.join(", ") + "}"
        elsif params.size > 0
          args = ", " + params.map{|i| i[0]}.join(", ")
        end

        return_cast = ""
        convert_return = ""
        if attribute("return") && attribute("return") != "void"
          if (attribute("return").include?(".") or attribute("return") == "int[]")
            return_class = attribute("return")
          elsif attribute("return") == 'int'
            return_class = 'Integer'
          else
            return_class = attribute("return").capitalize
          end
          return_cast = "return (#{return_class.gsub("&lt;", "<").gsub("&gt;", ">")}) " if return_class
          convert_return = ", #{return_class}.class"
        end

        if on_ruby_instance
          args = params.map{|i| "$arg_#{i[0]}"}.join(", ")
          params.map{|i| "JRubyAdapter.put(\"$arg_#{i[0]}\", #{i[0]});"} +
          [
              'JRubyAdapter.put("$ruby_instance", this);',
              "#{return_cast}JRubyAdapter.runScriptlet(\"$ruby_instance.#{camelize ? attribute("name") : snake_case_attribute}(#{args})\");",
          ]
        else
          ["#{return_cast}JRubyAdapter.callMethod(callbackProcs[#{constant_string}], \"call\" #{args}#{convert_return});"]
        end
      end

      def snake_case_attribute
        attribute("name").gsub(/[A-Z]/) { |i| "_#{i}" }.downcase
      end

      def method_definition
        method_call(
            (attribute("return") ? attribute("return") : "void"),
            attribute("name"), parameters,
            if_else(
                "JRubyAdapter.isInitialized()",
                if_else(
                    "callbackProcs != null && callbackProcs[#{constant_string}] != null",
                    [super_string] + ruby_call,
                    ['String rubyClassName = Script.toCamelCase(scriptName);'] +
                        if_else(
                            # TODO(uwe):  Remove defined?(rubyClassName) if we remove non-class-based class definitions
                            "(Boolean)JRubyAdapter.runScriptlet(\"defined?(\" + rubyClassName + \") == 'constant' && \" + rubyClassName + \".instance_methods(false).any?{|m| m.to_sym == :#{snake_case_attribute}}\")",
                            [super_string] + ruby_call(true),
                            if_else(
                                # TODO(uwe):  Remove defined?(rubyClassName) if we remove non-class-based class definitions
                                "(Boolean)JRubyAdapter.runScriptlet(\"defined?(\" + rubyClassName + \") == 'constant' && \" + rubyClassName + \".instance_methods(false).any?{|m| m.to_sym == :#{attribute('name')}}\")",
                                [super_string] + ruby_call(true, true),
                                [super_return]
                            )
                        )
                ),
                [
                    %Q{Log.i("Method called before JRuby runtime was initialized: " + getClass().getSimpleName() + "##{attribute('name')}");},
                    super_return,
                ]
            )
        ).indent.join("\n")
      end

      def constructor_definition(class_name)
        method_call("", class_name, parameters, [super_string]).indent.join("\n")
      end
    end
  end
end
