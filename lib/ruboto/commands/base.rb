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

# Decorate Main with all our modules
module Main
  include Ruboto::Util::LogAction
  include Ruboto::Util::CodeFormatting
  include Ruboto::Util::Build
  include Ruboto::Util::Update
  include Ruboto::Util::Verify
  include Ruboto::Util::ScanInAPI
end

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

              option("name"){
                required
                argument :required
                description "Name of your app"
              }
              option("target") {
                required
                argument :required
                defaults 'android-9'
                description "android version to target. must begin with 'android-' (e.g., 'android-8' for froyo)"
              }
              option("min_sdk") {
                required
                argument :required
                defaults 'android-7'
                description "minimum android version supported. must begin with 'android-'. (default 'android-3')"
              }
              option("path"){
                required
                argument :required
                description "path to where you want your app."
              }
              option("package"){
                required
                argument :required
                defaults 'org.ruboto.example'
                description "Name of package. Must be unique for every app. A common pattern is yourtld.yourdomain.appname (Ex. org.ruboto.irb)"
              }
              option("activity"){
                required
                argument :required
                defaults 'Main'
                description "name of your primary Activity"
              }

              def run
                path = params['path'].value
                name = params['name'].value
                target = params['target'].value
                min_sdk = params['min_sdk'].value
                package = params['package'].value
                activity = params['activity'].value

                abort "path must be to a directory that does not yet exist. it will be created" if
                File.exists?(path)

                root = File.expand_path(path)
                print "\nGenerating Android app #{name} in #{root}..."
                system "android create project -n #{name} -t #{target} -p #{path} -k #{package} -a #{activity}"
                puts "Done"

                print "\nGenerating Android test project #{name} in #{root}..."
                system "android create test-project -m .. -n #{name}Test -p #{path}/test"
                FileUtils.rm_rf File.join(root, 'test', 'src', package.split('.'))
                puts "Done"

                puts "\nCopying files:"
                copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, root

                %w{Rakefile .gitignore assets test}.each do |f|
                  log_action(f) {copier.copy f}
                end

                log_action("Ruboto java classes"){copier.copy "src/org/ruboto/*.java", "src/org/ruboto"}
                log_action("Ruboto java test classes"){copier.copy "src/org/ruboto/test/*.java", "test/src/org/ruboto/test"}

                Dir.chdir root do
                  update_jruby true

                  log_action("\nAdding activities (RubotoActivity and RubotoDialog) and SDK versions to the manifest") do
                    verify_manifest.elements['application'].add_element 'activity', {"android:name" => "org.ruboto.RubotoActivity"}
                    verify_manifest.elements['application'].add_element 'activity', {"android:name" => "org.ruboto.RubotoDialog",
                      "android:theme" => "@android:style/Theme.Dialog"}
                      verify_manifest.add_element 'uses-sdk', {"android:minSdkVersion" => min_sdk[/\d+/], "android:targetSdkVersion" => target[/\d+/]}
                      File.open("AndroidManifest.xml", 'w') {|f| verify_manifest.document.write(f, 4)}
                    end

                    update_ruboto true

                    generate_core_classes(:class => "all", :method_base => "on", :method_include => "", :method_exclude => "", :force => true, :implements => "")
                  end

                  log_action("Generating the default Activity and script") do
                    generate_inheriting_file "Activity", activity, package, "#{underscore(activity)}.rb", path
                  end

                  Dir.chdir File.join(root, 'test') do
                    test_manifest = REXML::Document.new(File.read('AndroidManifest.xml')).root
                    test_manifest.elements['instrumentation'].attributes['android:name'] = 'org.ruboto.test.InstrumentationTestRunner'
                    File.open("AndroidManifest.xml", 'w') {|f| test_manifest.document.write(f, 4)}
                    File.open('build.properties', 'a'){|f| f.puts 'test.runner=org.ruboto.test.InstrumentationTestRunner'}
                    ant_setup_line = "  <setup/>\n"
                    run_tests_override = <<-EOF
                    <macrodef name="run-tests-helper">
                    <attribute name="emma.enabled" default="false"/>
                    <element name="extra-instrument-args" optional="yes"/>
                    <sequential>
                    <echo>Running tests ...</echo>
                    <exec executable="${adb}" failonerror="true" outputproperty="tests.output">
                    <arg line="${adb.device.arg}"/>
                    <arg value="shell"/>
                    <arg value="am"/>
                    <arg value="instrument"/>
                    <arg value="-w"/>
                    <arg value="-e"/>
                    <arg value="coverage"/>
                    <arg value="@{emma.enabled}"/>
                    <extra-instrument-args/>
                    <arg value="${manifest.package}/${test.runner}"/>
                    </exec>
                    <echo message="${tests.output}"/>
                    <fail message="Tests failed!!!">
                    <condition>
                    <contains string="${tests.output}" substring="FAILURES"/>
                    </condition>
                    </fail>
                    </sequential>
                    </macrodef>

                    EOF
                    ant_script = File.read('build.xml').gsub(ant_setup_line, ant_setup_line + run_tests_override)
                    File.open('build.xml', 'w'){|f| f << ant_script}
                  end

                  puts "\nHello, #{name}\n"
                end
              end

              mode "class" do
                include Ruboto::Util::Build
                include Ruboto::Util::Verify

                argument("class"){
                  required
                  description "the Android Class that you want."
                }

                option("script_name"){
                  argument :required
                  description "name of the ruby script in assets/scripts/ that this class will execute. should end in .rb. optional"
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
                end
              end

              mode "subclass" do
                argument("class"){
                  required
                  description "the Android Class that you want to subclass (e.g., package.Class)."
                }

                option("name"){
                  required
                  argument :required
                  description "name of the class (and file). Should be CamelCase"
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
                  cast :boolean
                  description "force added and deprecated methods not excluded to be create"
                }

                def run
                  generate_subclass_or_interface(
                  %w(class name method_base method_include method_exclude implements force).inject({}) {|h, i| h[i.to_sym] = params[i].value; h})
                end
              end

              mode "interface" do
                argument("interface"){
                  required
                  description "the Android Interface that you want to implement (e.g., package.Interface)."
                }

                option("name"){
                  required
                  argument :required
                  description "name of the class (and file) that will implement the interface. Should be CamelCase"
                }

                option("force"){
                  cast :boolean
                  description "force added and deprecated interfaces to be create"
                }

                def run
                  generate_subclass_or_interface %w(interface name force).inject({}) {|h, i| h[i.to_sym] = params[i].value; h}
                end
              end

              mode "core" do
                argument("class"){
                  required
                  validate {|i| %w(Activity Service BroadcastReceiver View PreferenceActivity TabActivity OnClickListener OnItemClickListener all).include?(i)}
                  description "Activity, Service, BroadcastReceiver, View, OnClickListener, OnItemClickListener, or all (default = all); Other activities not included in 'all': PreferenceActivity, TabActivity"
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
                  cast :boolean
                  description "force added and deprecated methods not excluded to be create"
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
              argument("what"){
                required
                validate {|i| %w(jruby ruboto).include?(i)}
                description "What do you want to update: 'jruby' or 'ruboto'"
              }

              option("force"){
                description "force and update even if the version hasn't changed"
              }

              def run
                case params['what'].value
                when "jruby" then
                  update_jruby(params['force'].value)
                  Dir.chdir 'test' do
                    update_jruby params['force'].value
                  end
                when "ruboto" then
                  update_ruboto(params['force'].value)
                  Dir.chdir 'test' do
                    update_ruboto params['force'].value
                  end
                end
              end
            end

            # just running `ruboto`
            def run
              puts %Q{
                Ruboto -- Ruby for Android
                Execute `ruboto gen app --help` for instructions on how to generate a fresh Ruby-enabled Android app
                Execute `ruboto --help` for other options
              }
            end
          }
        end
      end
    end
  end