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
      include Ruboto::Util::Build
      include Ruboto::SdkVersions
      include Ruboto::Util::Verify

      API_LEVEL_PATTERN = /^(android|google_apis)-(\d+)$/
      API_NUMBER_PATTERN = /(\d+)/
      VERSION_HELP_TEXT = "(e.g., 'android-19' or '19' for kitkat, " \
          "'google_apis-23' for Android 6.0 with Google APIs)"

      def self.main
        Main do
          mode 'init' do
            require 'ruboto/util/update'
            include Ruboto::Util::LogAction
            include Ruboto::Util::Build
            include Ruboto::Util::Update

            option('path') {
              # argument :required
              description 'Path to where you want your app.  Defaults to the last part of the package name.'
            }
            option('with-jruby') {
              description 'Install the JRuby jars in your libs directory.  Optionally set the JRuby version to install.  Otherwise the latest available version is installed.'
              argument :optional
              cast { |v| Gem::Version.new(v) }
              validate { |v| Gem::Version.correct?(v) }
            }
            def run
              path = params['path'].value || Dir.getwd
              with_jruby = params['with-jruby'].value
              with_jruby = '9.2.9.0' unless with_jruby.is_a?(Gem::Version)

              root = File.expand_path(path)

              abort "Path (#{path}) must be to a directory that already exists." unless Dir.exist?(root)

              puts "\nInitializing Android app in #{root}..."

              Dir.chdir root do
                update_assets
                update_ruboto true
                # update_icons true
                update_classes nil, 'exclude'
                # if with_jruby
                #   update_jruby true, with_jruby
                #   # update_dx_jar true
                # end
                update_core_classes 'exclude'

                # log_action('Generating the default Activity and script') do
                #   generate_inheriting_file 'Activity', activity, package
                # end
                # FileUtils.touch 'bin/classes2.dex'
              end

              puts "\nRuboto app in #{path} initialized."
            end
          end
          mode 'gen' do
            require 'ruboto/util/update'

            mode 'jruby' do
              include Ruboto::Util::LogAction
              include Ruboto::Util::Build
              include Ruboto::Util::Update

              argument('version') {
                required false
                description 'The JRuby version to install.'
                cast { |v| Gem::Version.new(v) }
                validate { |v| Gem::Version.correct?(v) }
              }

              def run
                update_jruby true, params['version'].value
              end
            end

            mode 'class' do
              include Ruboto::Util::Build

              argument('class') {
                required
                alternatives = Dir[File.join(Ruboto::ASSETS, "#{JAVA_SRC_DIR}/Inheriting*.java")].map { |f| File.basename(f)[10..-6] } - %w(Class)
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

            mode 'app' do
              # FIXME(uwe): Change to cast to integer for better comparison
              option('target', 't') {
                argument :required
                description "Android version to target #{VERSION_HELP_TEXT}"
                cast { |t| t =~ API_NUMBER_PATTERN ? "android-#$1" : t }
                validate { |t| t =~ API_LEVEL_PATTERN }
              }
              option('with-jruby') {
                description 'Install the JRuby jars in your libs directory.  Optionally set the JRuby version to install.  Otherwise the latest available version is installed.  If the JRuby jars are already present in your project, this option is implied.'
                argument :optional
                cast { |v| Gem::Version.new(v) }
                validate { |v| Gem::Version.correct?(v) }
              }
              option('force') {
                description "force an update even if the version hasn't changed"
              }

              def run
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

                if (target = params['target'].value)
                  unless target =~ API_LEVEL_PATTERN
                    abort "Target must match #{API_LEVEL_PATTERN}: got #{target}"
                  end

                  unless $2.to_i >= MINIMUM_SUPPORTED_SDK_LEVEL
                    abort "Minimum Android api level is #{MINIMUM_SUPPORTED_SDK}: got #{target}"
                  end

                  target_level = target[API_NUMBER_PATTERN]
                  update_android(target_level)
                  update_test force, target_level
                else
                  update_android
                  update_test force
                end

                update_assets old_version
                update_ruboto force
                update_classes old_version, force
                update_dx_jar force
                update_jruby force, params['with-jruby'].value
                update_manifest nil, nil, force
                update_icons force
                update_core_classes 'exclude'
                update_bundle
              end
            end

            mode 'jruby' do

              argument('version') {
                required false
                description 'The JRuby version to install.  The jruby-jars gem of the same version should be installed on your system already.'
                cast { |v| Gem::Version.new(v) }
                validate { |v| Gem::Version.correct?(v) }
              }

              option('force') {
                description "force an update even if the version hasn't changed"
              }

              def run
                update_jruby(params['force'].value, params['version'].value, true) || abort
              end
            end
          end

          mode 'setup' do
            require 'ruboto/util/setup'
            include Ruboto::Util::Setup

            option('target', 't') {
              description "sets the target Android API level to set up for #{VERSION_HELP_TEXT}"
              argument :required
              default DEFAULT_TARGET_SDK
              arity -1
              cast { |t| t =~ API_NUMBER_PATTERN ? "android-#$1" : t }
              validate { |t| t =~ API_LEVEL_PATTERN }
            }

            option('yes', 'y') {
              description 'answer "yes" to all interactive questions.  Will automatically install needed components.'
            }

            option('update', 'u') {
                description 'updates intel haxm'
            }

            option('upgrade') {
                description 'DEPRECATED:  Use --update instead'
            }

            def run
              update = params['update'].value

              # FIXME(uwe): Remove after Ruboto 1.5.0 is released
              update ||= params['upgrade'].value
              # EMXIF

              setup_ruboto(params['yes'].value, params['target'].values, update)
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
              examples Ruboto::SdkVersions::API_LEVEL_TO_VERSION.keys.join(', ')
              required unless api_level
              argument :required
              default(api_level) if api_level
              cast { |t| t =~ API_NUMBER_PATTERN ? "android-#$1" : t }
              validate { |t| t =~ API_LEVEL_PATTERN && sdk_level_name($2.to_i) }
            }

            option('no-snapshot', 's') {
              description 'do not use a snapshot when starting the emulator'
            }

            def run
              start_emulator(params['target'].value, params['no-snapshot'].value)
            end
          end

          option 'version' do
            description 'display ruboto version'
          end

          # just running `ruboto`
          def run
            version = Gem::Specification.find_by_name('ruboto').version.version

            if params['version'].value
              puts version
            else
              puts <<EOF

    Ruboto -- Ruby for Android #{version}
    Execute `ruboto init to initialize an Android Studio project with Ruboto
    Execute `ruboto --help` for other options

EOF
            end
          end
        end
      end
    end
  end
end
