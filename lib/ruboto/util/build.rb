module Ruboto
  module Util
    module Build
      include Verify
      SCRIPTS_DIR = 'src'
      
      ###########################################################################
      #
      # Build Subclass or Interface:
      #

      #
      # build_file: Reads the src from the appropriate location,
      #   uses the substitutions hash to modify the contents,
      #   and writes to the new location
      #
      def build_file(src, package, name, substitutions, dest='.')
        to = File.join(dest, "src/#{package.gsub('.', '/')}")
        Dir.mkdir(to) unless File.directory?(to)

        text = File.read(File.expand_path(Ruboto::GEM_ROOT + "/assets/src/#{src}.java"))
        substitutions.each {|k,v| text.gsub!(k, v)}

        File.open(File.join(to, "#{name}.java"), 'w') {|f| f << text}
      end

      #
      # get_class_or_interface: Opens the xml file and locates the specified class.
      #   Aborts if the class is not found or if it is not available for
      #   all api levels
      #
      def get_class_or_interface(klass, force=nil)
        element = verify_api.find_class_or_interface(klass, "either")

        abort "ERROR: #{klass} not found" unless element

        unless force == "include"
          abort "#{klass} not available in minSdkVersion, added in #{element.attribute('api_added')}; use '--force include' to create it" if
            element.attribute('api_added') and element.attribute('api_added').to_i > verify_min_sdk.to_i
          abort "#{klass} deprecated for targetSdkVersion, deprecatrd in #{element.attribute('deprecated')}; use '--force include' to create it" if
            element.attribute('deprecated') and element.attribute('deprecated').to_i <= verify_target_sdk.to_i
        end

        abort "#{klass} removed for targetSdkVersion, removed in #{element.attribute('api_removed')}" if
          element.attribute('api_removed') and element.attribute('api_removed').to_i <= verify_target_sdk.to_i

        element
      end

      #
      # check_methods: Checks the methods to see if they are available for all api levels
      #
      def check_methods(methods, force=nil)
        min_api = verify_min_sdk.to_i
        target_api = verify_target_sdk.to_i

        # Remove methods changed outside of the scope of the sdk versions
        methods = methods.select{|i| not i.attribute('api_added') or i.attribute('api_added').to_i <= target_api}
        methods = methods.select{|i| not i.attribute('deprecated') or i.attribute('deprecated').to_i > min_api}
        methods = methods.select{|i| not i.attribute('api_removed') or i.attribute('api_removed').to_i > min_api}

        # Inform and remove methods that do not exist in one of the sdk versions
        methods = methods.select do |i|
          if i.attribute('api_removed') and i.attribute('api_removed').to_i <= target_api
            puts "Can't create #{i.method_signature} -- removed in #{i.attribute('api_removed')}"
            false
          else
            true
          end
        end

        abort = false
        new_methods = methods
        unless force == "include"
          # Inform and remove methods changed inside the scope of the sdk versions
          new_methods = methods.select do |i|
            if i.attribute('api_added') and i.attribute('api_added').to_i > min_api and force == "exclude"
              false
            elsif i.attribute('api_added') and i.attribute('api_added').to_i > min_api
              puts "Can't create #{i.method_signature} -- added in #{i.attribute('api_added')} -- use method_exclude or force exclude"
              abort = true
              false
            elsif i.attribute('deprecated') and i.attribute('deprecated').to_i <= target_api and force == "exclude"
              false
            elsif i.attribute('deprecated') and i.attribute('deprecated').to_i <= target_api
              puts "Can't create #{i.method_signature} -- deprecated in #{i.attribute('deprecated')} -- use method_exclude or force exclude"
              abort = true
              false
            else
              true
            end
          end

          abort("Aborting!") if abort
        end

        new_methods
      end

      #
      # generate_subclass_or_interface: Creates a subclass or interface based on the specifications.
      #
      def generate_subclass_or_interface(params)
        defaults = {:template => "InheritingClass", :method_base => "all", :method_include => "", :method_exclude => "", :force => nil, :implements => ""}
        params = defaults.merge(params)
        params[:package] ||= verify_package

        class_desc = get_class_or_interface(params[:class] || params[:interface], params[:force])

        print "Generating methods for #{params[:name]}..."
        methods = class_desc.all_methods(params[:method_base], params[:method_include], params[:method_exclude], params[:implements])
        methods = check_methods(methods, params[:force])
        puts "Done. Methods created: #{methods.count}"

        # Remove any duplicate constants (use *args handle multiple parameter lists)
        constants = methods.map(&:constant_string).uniq

        build_file params[:template], params[:package], params[:name], {
          "THE_PACKAGE" => params[:package],
          "THE_ACTION" => class_desc.name == "class" ? "extends" : "implements",
          "THE_ANDROID_CLASS" => (params[:class] || params[:interface]) +
          (params[:implements] == "" ? "" : (" implements " + params[:implements].split(",").join(", "))),
          "THE_RUBOTO_CLASS" => params[:name],
          "THE_CONSTANTS" =>  constants.map {|i| "public static final int #{i} = #{constants.index(i)};"}.indent.join("\n"),
          "CONSTANTS_COUNT" => methods.count.to_s,
          "THE_CONSTRUCTORS" => class_desc.name == "class" ?
          class_desc.get_elements("constructor").map{|i| i.constructor_definition(params[:name])}.join("\n\n") : "",
          "THE_METHODS" => methods.map{|i| i.method_definition(params[:name])}.join("\n\n")
        }
      end

      #
      # generate_core_classe: generates RubotoActivity, RubotoService, etc. based
      #   on the API specifications.
      #
      def generate_core_classes(params)
        hash = {:package => "org.ruboto"}
        %w(method_base method_include implements force).inject(hash) {|h, i| h[i.to_sym] = params[i.to_sym]; h}
        hash[:method_exclude] = params[:method_exclude].split(",").push("onCreate").join(",")

        %w(android.app.Activity android.app.Service android.content.BroadcastReceiver).each do |i|
          name = i.split(".")[-1]
          if(params[:class] == name or params[:class] == "all")
            generate_subclass_or_interface(hash.merge({:template => "Ruboto#{name}", :class => i, :name => "Ruboto#{name}"}))
          end
        end

        # Activities that can be created, but only directly  (i.e., not included in all)
        %w(android.preference.PreferenceActivity android.app.TabActivity).each do |i|
          name = i.split(".")[-1]
          if params[:class] == name
            generate_subclass_or_interface(hash.merge({:template => "RubotoActivity", :class => i, :name => "Ruboto#{name}"}))
          end
        end
      end

      ###########################################################################
      #
      # generate_inheriting_file:
      #   Builds a script based subclass of Activity, Service, or BroadcastReceiver
      #
      def generate_inheriting_file(klass, name, package, script_name = "#{underscore(name)}.rb")
        dest = '.'
        file = File.expand_path File.join(dest, "src/#{package.gsub('.', '/')}", "#{name}.java")
        text = File.read(File.join(Ruboto::ASSETS, "src/Inheriting#{klass}.java"))
        file_existed = File.exists?(file)
        File.open(file, 'w') do |f|
          f << text.gsub("THE_PACKAGE", package).gsub("Sample#{klass}", name).gsub("Inheriting#{klass}", name).gsub("sample_#{underscore(klass)}.rb", script_name)
        end
        puts "#{file_existed ? 'Updated' : 'Added'} file #{file}."

        script_file = File.expand_path("#{SCRIPTS_DIR}/#{script_name}", dest)
        if !File.exists? script_file
          sample_source = File.read(File.join(Ruboto::ASSETS, "samples/sample_#{underscore klass}.rb"))
          sample_source.gsub!("THE_PACKAGE", package)
          sample_source.gsub!("Sample#{klass}", name)
          sample_source.gsub!("start.rb", script_name)
          FileUtils.mkdir_p File.join(dest, SCRIPTS_DIR)
          File.open script_file, "a" do |f|
            f << sample_source
          end
          puts "Added file #{script_file}."
        end

        test_file = File.expand_path("test/src/#{script_name.chomp('.rb')}_test.rb", dest)
        if !File.exists? test_file
          sample_test_source = File.read(File.join(Ruboto::ASSETS, "samples/sample_#{underscore klass}_test.rb"))
          sample_test_source.gsub!("THE_PACKAGE", package)
          sample_test_source.gsub!("Sample#{klass}", name)
          sample_test_source.gsub!('SampleActivity', verify_activity)
          File.open test_file, "a" do |f|
            f << sample_test_source
          end
          puts "Added file #{test_file}."
        end
      end
    end
  end
end
