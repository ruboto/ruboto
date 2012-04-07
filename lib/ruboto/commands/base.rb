# Base Ruboto stuff and dependencies
require 'ruboto'

# Command-specific dependencies
require 'ruboto/util/asset_copier'
require 'ruboto/util/log_action'
require 'ruboto/util/xml_element'
require 'ruboto/util/code_formatting'
require 'ruboto/util/build'
require 'ruboto/util/update'
require 'ruboto/util/verify'
require 'ruboto/util/scan_in_api'
require 'ruboto/core_ext/array'
require 'ruboto/core_ext/object'

module Ruboto
  module Commands
    module Base
      def self.main
        Main {
          mode "gen" do
            mode "app" do
              include Ruboto::Util::LogAction
              include Ruboto::Util::Build
              include Ruboto::Util::Update
              include Ruboto::Util::Verify

              option("package"){
                required
                argument :required
                description "Name of package. Must be unique for every app. A common pattern is yourtld.yourdomain.appname (Ex. org.ruboto.irb)"
              }
              option("name"){
                argument :required
                description "Name of your app.  Defaults to the last part of the package name capitalized."
              }
              option("activity"){
                argument :required
                description "Name of your primary Activity.  Defaults to the name of the application with Activity appended."
              }
              option("path"){
                argument :required
                description "Path to where you want your app.  Defaults to the last part of the package name."
              }
              option("target") {
                argument :required
                defaults MINIMUM_SUPPORTED_SDK
                description "Android version to target. Must begin with 'android-' (e.g., 'android-8' for froyo)"
              }
              option("min-sdk") {
                argument :required
                description "Minimum android version supported. Must begin with 'android-'."
              }
              option("with-jruby") {
                description "Generate the JRuby jars jar"
                cast :boolean
              }

              def run
                package = params['package'].value
                name = params['name'].value || package.split('.').last.split('_').map{|s| s.capitalize}.join
                activity = params['activity'].value || "#{name}Activity"
                path = params['path'].value || package.split('.').last
                target = params['target'].value
                min_sdk = params['min-sdk'].value || target

                abort "Path (#{path}) must be to a directory that does not yet exist. It will be created." if File.exists?(path)
                abort "Target must match android-<number>: got #{target}" unless target =~ /^android-(\d+)$/
                abort "Minimum Android api level is #{MINIMUM_SUPPORTED_SDK}: got #{target}" unless $1.to_i >= MINIMUM_SUPPORTED_SDK_LEVEL

                root = File.expand_path(path)
                puts "\nGenerating Android app #{name} in #{root}..."
                system "android create project -n #{name} -t #{target} -p #{path} -k #{package} -a #{activity}"
                exit $? unless $? == 0
                unless File.exists? path
                  puts "Android project was not created"
                  exit_failure!
                end
                Dir.chdir path do
                  FileUtils.rm_f "src/#{package.gsub '.', '/'}/#{activity}.java"
                  puts "Removed file #{"src/#{package.gsub '.', '/'}/#{activity}"}.java"
                  FileUtils.rm_f 'res/layout/main.xml'
                  puts 'Removed file res/layout/main.xml'
                  verify_strings.root.elements['string'].text = name.gsub(/([A-Z]+)([A-Z][a-z])/,'\1 \2').gsub(/([a-z\d])([A-Z])/,'\1 \2')
                  File.open("res/values/strings.xml", 'w') {|f| verify_strings.document.write(f, 4)}
                end
                puts "Done"

                Dir.chdir root do
                  update_test true
                  update_assets
                  update_ruboto true
                  update_icons true
                  update_classes true
                  update_jruby true if params['with-jruby'].value
#                  update_build_xml
                  update_manifest min_sdk[/\d+/], target[/\d+/], true
                  update_core_classes "exclude"

                  log_action("Generating the default Activity and script") do
                    generate_inheriting_file "Activity", activity, package
                  end
                end

                puts "\nHello, #{name}\n"
              end
            end

            mode "jruby" do
              include Ruboto::Util::LogAction
              include Ruboto::Util::Build
              include Ruboto::Util::Update
              include Ruboto::Util::Verify

              def run
                Dir.chdir root do
                  update_jruby true
                end
              end
            end

            mode "class" do
              include Ruboto::Util::Build
              include Ruboto::Util::Verify

              argument("class"){
                required
                alternatives = Dir[File.join(Ruboto::ASSETS, "src/Inheriting*.java")].map{|f| File.basename(f)[10..-6]} - ['Class']
                description "the Android Class that you want: #{alternatives[0..-2].map{|c| "#{c}, "}}or #{alternatives[-1]}"
                validate {|v| alternatives.include? v}
              }

              option("script_name"){
                argument :required
                description "name of the ruby script that this class will execute. Should end in .rb.  Optional."
              }

              option("name"){
                required
                argument :required
                description "name of the class (and file). Should be CamelCase"
              }

              def run
                name = params['name'].value
                script_name = params['script_name'].value || "#{underscore(name)}.rb"
                klass = params['class'].value

                generate_inheriting_file klass, name, verify_package, script_name

                app_element = verify_manifest.elements['application']
                if klass == 'Activity' || klass == 'Service'
                  tag = klass.downcase
                  if app_element.elements["#{tag}[@android:name='#{name}']"]
                    puts "#{klass} already present in manifest."
                  else
                    app_element.add_element tag, {"android:name" => "#{"#{verify_package}." if klass == 'Service'}#{name}"}
                    save_manifest
                    puts "Added #{tag} to manifest."
                  end
                end
              end
            end

            mode "subclass" do
              include Ruboto::Util::Build

              argument("class"){
                required
                description "the Android Class that you want to subclass (e.g., package.Class)."
              }

              option("name"){
                required
                argument :required
                description "name of the class (and file). Should be CamelCase"
              }

              option("package"){
                argument :required
                description "package for the new class (if not specified, uses project package)"
              }

              option("method_base"){
                required
                validate {|i| %w(all on none abstract).include?(i)}
                argument :required
                description "the base set of methods to generate (adjusted with method_include and method_exclude): all, none, abstract, on (e.g., onClick)"
              }

              option("method_include"){
                argument :required
                defaults ""
                description "additional methods to add to the base list"
              }

              option("method_exclude"){
                argument :required
                defaults ""
                description "methods to remove from the base list"
              }

              option("implements"){
                required
                argument :required
                defaults ""
                description "comma separated list interfaces to implement"
              }

              option("force"){
                argument :required
                validate {|i| %w(include exclude).include?(i)}
                description "force handling of added and deprecated methods (values: 'include' or 'exclude') unless individually included or excluded"
              }

              def run
                generate_subclass_or_interface(
                %w(class name package method_base method_include method_exclude implements force).inject({}) {|h, i| h[i.to_sym] = params[i].value; h})
              end
            end

            mode "interface" do
              include Ruboto::Util::Build

              argument("interface"){
                required
                description "the Android Interface that you want to implement (e.g., package.Interface)."
              }

              option("name"){
                required
                argument :required
                description "name of the class (and file) that will implement the interface. Should be CamelCase"
              }

              option("package"){
                argument :required
                description "package for the new class (if not specified, uses project package)"
              }

              option("force"){
                argument :required
                validate {|i| %w(include exclude).include?(i)}
                description "force added and deprecated interfaces (values: 'include' or 'exclude')"
              }

              def run
                generate_subclass_or_interface %w(interface name package force).inject({}) {|h, i| h[i.to_sym] = params[i].value; h}
              end
            end

            mode "core" do
              include Ruboto::Util::Build

              argument("class"){
                required
                validate {|i| %w(Activity Service BroadcastReceiver View PreferenceActivity TabActivity OnClickListener OnItemClickListener OnItemSelectedListener all).include?(i)}
                description "Activity, Service, BroadcastReceiver, View, OnClickListener, OnItemClickListener, OnItemSelectedListener, or all (default = all); Other activities not included in 'all': PreferenceActivity, TabActivity"
              }

              option("method_base"){
                required
                argument :required
                validate {|i| %w(all on none).include?(i)}
                defaults "on"
                description "the base set of methods to generate (adjusted with method_include and method_exclude): all, none, on (e.g., onClick)"
              }

              option("method_include"){
                required
                argument :required
                defaults ""
                description "additional methods to add to the base list"
              }

              option("method_exclude"){
                required
                argument :required
                defaults ""
                description "methods to remove from the base list"
              }

              option("implements"){
                required
                argument :required
                defaults ""
                description "for classes only, interfaces to implement (cannot be used with 'gen core all')"
              }

              option("force"){
                argument :required
                validate {|i| %w(include exclude).include?(i)}
                description "force handling of added and deprecated methods (values: 'include' or 'exclude') unless individually included or excluded"
              }

              def run
                abort("specify 'implements' only for Activity, Service, BroadcastReceiver, PreferenceActivity, or TabActivity") unless
                %w(Activity Service BroadcastReceiver PreferenceActivity TabActivity).include?(params["class"].value) or params["implements"].value == ""
                generate_core_classes [:class, :method_base, :method_include, :method_exclude, :implements, :force].inject({}) {|h, i| h[i] = params[i.to_s].value; h}
              end
            end

            mode "key" do
              option("keystore"){
                default "~/.android/production.keystore"
                description "path to where the keystore will be saved. defaults to ~/.android/production.keystore"
              }

              option("alias"){
                required
                description "The 'alias' for the key. Identifies the key within the keystore. Required"
              }

              def run
                keystore = params['keystore'].value
                key_alias = params['alias'].value

                `keytool -genkey -keyalg rsa -keysize 4096 -validity 1000000 -keystore #{keystore} -alias #{key_alias}`
              end
            end
          end

          mode "update" do
            include Ruboto::Util::LogAction
            include Ruboto::Util::Update
            include Ruboto::Util::Verify

            argument("what") {
              required
              validate {|i| %w(jruby app ruboto).include?(i)}
              description "What do you want to update: 'app', 'jruby', or 'ruboto'"
            }

            option("force") {
              description "force an update even if the version hasn't changed"
            }

            def run
              case params['what'].value
              when "app" then
                force = params['force'].value
                update_android
                update_test force
                update_assets
                update_ruboto force
                update_icons force
                update_classes force
                update_jruby force
                update_manifest nil, nil, force
                update_core_classes "exclude"
                update_bundle
              when "jruby" then
                update_jruby(params['force'].value) || abort
              when "ruboto" then
                update_ruboto(params['force'].value) || abort
              end
            end
          end

          option "version" do
            description "display ruboto version"
          end

          # just running `ruboto`
          def run
            # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
            if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
              gem_spec = Gem::Specification.find_by_path 'ruboto'
            else
              gem_spec = Gem.searcher.find('ruboto')
            end
            # FIXME end

            version = gem_spec.version.version

            if params['version'].value
              puts version
            else
              puts %Q{
                Ruboto -- Ruby for Android #{version}
                Execute `ruboto gen app --help` for instructions on how to generate a fresh Ruby-enabled Android app
                Execute `ruboto --help` for other options
              }
            end
          end
        }
      end
    end
  end
end
