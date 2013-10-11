# Base Ruboto stuff and dependencies
require 'ruboto'

# Command-specific dependencies
require 'ruboto/sdk_versions'
require 'ruboto/util/asset_copier'
require 'ruboto/util/log_action'
require 'ruboto/util/xml_element'
require 'ruboto/util/code_formatting'
require 'ruboto/util/build'
require 'ruboto/util/verify'
require 'ruboto/util/scan_in_api'
require 'ruboto/core_ext/array'
require 'ruboto/core_ext/object'

module Ruboto
  module Commands
    module Base
      include Ruboto::SdkVersions
      include Ruboto::Util::Verify

      def self.main
        Main do
          mode 'gen' do
            require 'ruboto/util/update'

            mode 'app' do
              include Ruboto::Util::LogAction
              include Ruboto::Util::Build
              include Ruboto::Util::Update

              option('package') {
                required
                argument :required
                description 'Name of package. Must be unique for every app. A common pattern is yourtld.yourdomain.appname (Ex. org.ruboto.irb)'
              }
              option('name') {
                argument :required
                description 'Name of your app.  Defaults to the last part of the package name capitalized.'
              }
              option('activity') {
                argument :required
                description 'Name of your primary Activity.  Defaults to the name of the application with Activity appended.'
              }
              option('path') {
                argument :required
                description 'Path to where you want your app.  Defaults to the last part of the package name.'
              }
              option('target', 't') {
                argument :required
                defaults DEFAULT_TARGET_SDK
                description "Android version to target. Must begin with 'android-' (e.g., 'android-10' for gingerbread)"
              }
              option('min-sdk') {
                argument :required
                description "Minimum android version supported. Must begin with 'android-'."
              }
              option('with-jruby') {
                description 'Generate the JRuby jars jar'
                cast :boolean
              }
              option('force') {
                description 'Force creation of project even if the path exists'
                cast :boolean
              }

              def run
                package = params['package'].value
                name = params['name'].value || package.split('.').last.split('_').map { |s| s.capitalize }.join
                name[0..0] = name[0..0].upcase
                activity = params['activity'].value || "#{name}Activity"
                path = params['path'].value || package.split('.').last
                target = params['target'].value
                min_sdk = params['min-sdk'].value || target
                with_jruby = params['with-jruby'].value
                force = params['force'].value

                abort "Path (#{path}) must be to a directory that does not yet exist. It will be created." if !force && File.exists?(path)
                abort "Target must match android-<number>: got #{target}" unless target =~ /^android-(\d+)$/
                abort "Minimum Android api level is #{MINIMUM_SUPPORTED_SDK}: got #{target}" unless $1.to_i >= MINIMUM_SUPPORTED_SDK_LEVEL

                root = File.expand_path(path)
                puts "\nGenerating Android app #{name} in #{root}..."
                system "android create project -n #{name} -t #{target} -p #{path} -k #{package} -a #{activity}"
                exit $?.to_i unless $? == 0
                unless File.exists? path
                  puts 'Android project was not created'
                  exit_failure!
                end
                Dir.chdir path do
                  FileUtils.rm_f "src/#{package.gsub '.', '/'}/#{activity}.java"
                  puts "Removed file #{"src/#{package.gsub '.', '/'}/#{activity}"}.java"
                  FileUtils.rm_f 'res/layout/main.xml'
                  puts 'Removed file res/layout/main.xml'
                  verify_strings.root.elements['string'].text = name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2').gsub(/([a-z\d])([A-Z])/, '\1 \2')
                  File.open('res/values/strings.xml', 'w') { |f| verify_strings.document.write(f, 4) }
                end
                puts 'Done'

                Dir.chdir root do
                  update_manifest min_sdk[/\d+/], target[/\d+/], true
                  update_test true
                  update_assets
                  update_ruboto true
                  update_icons true
                  update_classes nil, 'exclude'
                  update_jruby true if with_jruby
                  update_dx_jar true if with_jruby
                  update_core_classes 'exclude'

                  log_action('Generating the default Activity and script') do
                    generate_inheriting_file 'Activity', activity, package
                  end
                end

                puts "\nHello, #{name}\n"
              end
            end

            mode 'jruby' do
              include Ruboto::Util::LogAction
              include Ruboto::Util::Build
              include Ruboto::Util::Update

              def run
                update_jruby true
              end
            end

            mode 'class' do
              include Ruboto::Util::Build

              argument('class') {
                required
                alternatives = Dir[File.join(Ruboto::ASSETS, 'src/Inheriting*.java')].map { |f| File.basename(f)[10..-6] } - %w(Class)
                description "the Android Class that you want: #{alternatives[0..-2].map { |c| "#{c}, " }}or #{alternatives[-1]}"
                validate { |v| alternatives.include? v }
              }

              option('script_name') {
                argument :required
                description 'name of the ruby script that this class will execute. Should end in .rb.  Optional.'
              }

              option('name') {
                required
                argument :required
                description 'name of the class (and file). Should be CamelCase'
              }

              def run
                name = params['name'].value
                name[0..0] = name[0..0].upcase
                script_name = params['script_name'].value || "#{underscore(name)}.rb"
                klass = params['class'].value

                generate_inheriting_file klass, name, verify_package, script_name

                app_element = verify_manifest.elements['application']
                if klass == 'Activity' || klass == 'Service'
                  tag = klass.downcase
                  if app_element.elements["#{tag}[@android:name='#{name}']"]
                    puts "#{klass} already present in manifest."
                  else
                    app_element.add_element tag, {'android:name' => "#{"#{verify_package}." if klass == 'Service'}#{name}"}
                    save_manifest
                    puts "Added #{tag} to manifest."
                  end
                end
              end
            end

            mode 'subclass' do
              include Ruboto::Util::Build

              argument('class') {
                required
                description 'the Android Class that you want to subclass (e.g., package.Class).'
              }

              option('name') {
                required
                argument :required
                description 'name of the class (and file). Should be CamelCase'
              }

              option('package') {
                argument :required
                description 'package for the new class (if not specified, uses project package)'
              }

              option('method_base') {
                required
                validate { |i| %w(all on none abstract).include?(i) }
                argument :required
                description 'the base set of methods to generate (adjusted with method_include and method_exclude): all, none, abstract, on (e.g., onClick)'
              }

              option('method_include') {
                argument :required
                defaults ''
                description 'additional methods to add to the base list'
              }

              option('method_exclude') {
                argument :required
                defaults ''
                description 'methods to remove from the base list'
              }

              option('implements') {
                required
                argument :required
                defaults ''
                description 'comma separated list interfaces to implement'
              }

              option('force') {
                argument :required
                validate { |i| %w(include exclude).include?(i) }
                description "force handling of added and deprecated methods (values: 'include' or 'exclude') unless individually included or excluded"
              }

              def run
                generate_inheriting_file 'Class', params['name'].value
                generate_subclass_or_interface(
                    %w(class name package method_base method_include method_exclude implements force).inject({}) { |h, i| h[i.to_sym] = params[i].value; h })
              end
            end

            mode 'interface' do
              include Ruboto::Util::Build

              argument('interface') {
                required
                description 'the Android Interface that you want to implement (e.g., package.Interface).'
              }

              option('name') {
                required
                argument :required
                description 'name of the class (and file) that will implement the interface. Should be CamelCase'
              }

              option('package') {
                argument :required
                description 'package for the new class (if not specified, uses project package)'
              }

              option('force') {
                argument :required
                validate { |i| %w(include exclude).include?(i) }
                description "force added and deprecated interfaces (values: 'include' or 'exclude')"
              }

              def run
                # FIXME(uwe):  DEPRECATED!  Remove before Ruboto version 1.0.0.
                puts "\nThe use of \"ruboto gen interface\" has been deprecated.  Please use\n\n    ruboto gen subclass\n\ninstead.\n\n"
                generate_inheriting_file 'Class', params['name'].value
                generate_subclass_or_interface %w(interface name package force).inject({}) { |h, i| h[i.to_sym] = params[i].value; h }
              end
            end

            mode 'core' do
              include Ruboto::Util::Build

              argument('class') {
                required
                validate { |i| %w(Activity Service BroadcastReceiver View PreferenceActivity TabActivity OnClickListener OnItemClickListener OnItemSelectedListener all).include?(i) }
                description "Activity, Service, BroadcastReceiver, View, OnClickListener, OnItemClickListener, OnItemSelectedListener, or all (default = all); Other activities not included in 'all': PreferenceActivity, TabActivity"
              }

              option('method_base') {
                required
                argument :required
                validate { |i| %w(all on none).include?(i) }
                defaults 'on'
                description 'the base set of methods to generate (adjusted with method_include and method_exclude): all, none, on (e.g., onClick)'
              }

              option('method_include') {
                required
                argument :required
                defaults ''
                description 'additional methods to add to the base list'
              }

              option('method_exclude') {
                required
                argument :required
                defaults ''
                description 'methods to remove from the base list'
              }

              option('implements') {
                required
                argument :required
                defaults ''
                description "for classes only, interfaces to implement (cannot be used with 'gen core all')"
              }

              option('force') {
                argument :required
                validate { |i| %w(include exclude).include?(i) }
                description "force handling of added and deprecated methods (values: 'include' or 'exclude') unless individually included or excluded"
              }

              def run
                abort("specify 'implements' only for Activity, Service, BroadcastReceiver, PreferenceActivity, or TabActivity") unless %w(Activity Service BroadcastReceiver PreferenceActivity TabActivity).include?(params['class'].value) or params['implements'].value == ''
                generate_core_classes [:class, :method_base, :method_include, :method_exclude, :implements, :force].inject({}) { |h, i| h[i] = params[i.to_s].value; h }
              end
            end
          end

          mode 'update' do
            require 'ruboto/util/update'
            include Ruboto::Util::LogAction
            include Ruboto::Util::Update

            argument('what') {
              required
              # FIXME(uwe): Deprecated "ruboto update ruboto" in Ruboto 0.8.1.  Remove september 2013.
              validate { |i| %w(jruby app ruboto).include?(i) }
              description "What do you want to update: 'app', 'jruby', or 'ruboto'"
            }

            option('force') {
              description "force an update even if the version hasn't changed"
            }

            def run
              case params['what'].value
              when 'app' then
                force = params['force'].value
                old_version = read_ruboto_version
                if old_version && Gem::Version.new(old_version) < Gem::Version.new(Ruboto::UPDATE_VERSION_LIMIT)
                  puts "Detected old Ruboto version: #{old_version}"
                  puts "Will use Ruboto #{Ruboto::UPDATE_VERSION_LIMIT} to update it first."
                  `gem query -i -n ruboto -v #{Ruboto::UPDATE_VERSION_LIMIT}`
                  system "gem install ruboto -v #{Ruboto::UPDATE_VERSION_LIMIT}" unless $? == 0
                  raise "Install of Ruboto #{Ruboto::UPDATE_VERSION_LIMIT} failed!" unless $? == 0
                  system "ruboto _#{Ruboto::UPDATE_VERSION_LIMIT}_ update app"
                  raise "Ruboto update app to #{Ruboto::UPDATE_VERSION_LIMIT} failed!" unless $? == 0
                end
                update_android
                update_test force
                update_assets
                update_ruboto force
                update_classes old_version, force
                update_dx_jar force
                update_jruby force
                update_manifest nil, nil, force
                update_icons force
                update_core_classes 'exclude'
                update_bundle
              when 'jruby' then
                update_jruby(params['force'].value, true) || abort
                # FIXME(uwe): Deprecated in Ruboto 0.8.1.  Remove september 2013.
              when 'ruboto' then
                puts "\nThe 'ruboto update ruboto' command has been deprecated.  Use\n\n    ruboto update app\n\ninstead.\n\n"
                update_ruboto(params['force'].value) || abort
              else
                raise "Unknown update target: #{params['what'].value.inspect}"
              end
            end
          end

          mode 'setup' do
            require 'ruboto/util/setup'
            include Ruboto::Util::Setup

            option('target', 't') {
              description 'sets the target Android API level to set up for (example: -t android-16)'
              argument :required
              default DEFAULT_TARGET_SDK
              arity -1
              cast {|t| t =~ /^(\d+)$/ ? "android-#$1" : t}
              validate {|t| t =~ /^android-\d+$/}
            }

            option('yes', 'y') {
              description 'answer "yes" to all interactive questions.  Will automatically install needed components.'
            }

            def run
              setup_ruboto(params['yes'].value, params['target'].values)
            end
          end

          mode 'emulator' do
            require 'ruboto/util/emulator'
            include Ruboto::Util::Emulator
            extend Ruboto::Util::Verify
            api_level = project_api_level

            option('target', 't') {
              extend Ruboto::Util::Emulator
              description 'sets the target Android API level for the emulator'
              examples Ruboto::Util::Emulator::API_LEVEL_TO_VERSION.keys.join(', ')
              required unless api_level
              argument :required
              default(api_level) if api_level
              cast {|t| t =~ /^(\d+)$/ ? "android-#$1" : t}
              validate {|t| t =~ /^android-(\d+)$/ && sdk_level_name($1.to_i)}
            }

            def run
              start_emulator(params['target'].value)
            end
          end

          option 'version' do
            description 'display ruboto version'
          end

          # just running `ruboto`
          def run
            # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
            if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
              gem_spec = Gem::Specification.find_by_path 'ruboto'
            else
              gem_spec = Gem.searcher.find('ruboto')
            end
            # EMXIF

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
        end
      end
    end
  end
end
