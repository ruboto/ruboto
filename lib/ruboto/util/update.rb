require 'ruboto/version'

module Ruboto
  module Util
    module Update
      include Build
      include Ruboto::SdkVersions

      ###########################################################################
      #
      # Updating components
      #

      def update_android
        root = Dir.getwd
        build_xml_file = "#{root}/build.xml"
        new_prop_file = "#{root}/project.properties"
        old_prop_file = "#{root}/default.properties"
        name = REXML::Document.new(File.read(build_xml_file)).root.attributes['name']

        # FIXME(uwe): Remove build.xml file to force regeneration.
        # FIXME(uwe): Needed when updating apps from Android SDK <= 13 to 14
        # FIXME(uwe): Remove when we stop supporting upgrading apps from Android SDK <= 13
        if File.read(build_xml_file) !~ /<!-- version-tag: 1 -->/
          puts "Forcing generation of new build.xml since upgrading a project generated with Android SDK 13 or older."
          FileUtils.rm_f build_xml_file
        end
        # EMXIF

        # FIXME(uwe):  Simplify when we stop supporting upgrading apps from Android SDK <= 13
        prop_file = File.exists?(new_prop_file) ? new_prop_file : old_prop_file
        version_regexp = /^(target=android-)(\d+)$/
        if (project_property_file = File.read(prop_file)) =~ version_regexp
          if $2.to_i < MINIMUM_SUPPORTED_SDK_LEVEL
            puts "Upgrading project to target #{MINIMUM_SUPPORTED_SDK}"
            File.open(prop_file, 'w') { |f| f << project_property_file.gsub(version_regexp, "\\1#{MINIMUM_SUPPORTED_SDK_LEVEL}") }
          end
        end
        # EMXIF

        system "android update project -p #{root} -n #{name}"
        raise "android update project failed with return code #{$?}" unless $? == 0
      end

      def update_test(force = nil)
        root = Dir.getwd
        if !File.exists?("#{root}/test")
          name = verify_strings.root.elements['string'].text.gsub(' ', '')
          puts "\nGenerating Android test project #{name} in #{root}..."
          system %Q{android create test-project -m "#{root.gsub('"', '\"')}" -n "#{name}Test" -p "#{root.gsub('"', '\"')}/test"}
          FileUtils.rm_rf File.join(root, 'test', 'src', verify_package.split('.'))
          puts "Done"
        else
          # FIXME(uwe): Remove build.xml file to force regeneration.
          # FIXME(uwe): Needed when updating apps from Android SDK <= 13 to 14
          FileUtils.rm_f "#{root}/test/build.xml"
        # EMXIF

          puts "\nUpdating Android test project #{name} in #{root}/test..."
          system "android update test-project -m #{root} -p #{root}/test"
          raise "android update test-project failed with return code #{$?}" unless $? == 0
        end

        Dir.chdir File.join(root, 'test') do
          test_manifest = REXML::Document.new(File.read('AndroidManifest.xml')).root
          test_manifest.elements['application'].attributes['android:icon'] ||= '@drawable/ic_launcher'
          test_manifest.elements['instrumentation'].attributes['android:name'] = 'org.ruboto.test.InstrumentationTestRunner'

          # TODO(uwe): Trying to push test scripts for faster test cycle, but failing...
          # if test_manifest.elements["uses-permission[@android:name='android.permission.WRITE_INTERNAL_STORAGE']"]
          #   puts 'Found permission tag'
          # else
          #   test_manifest.add_element 'uses-permission', {"android:name" => "android.permission.WRITE_INTERNAL_STORAGE"}
          #   puts 'Added permission tag'
          # end
          # if test_manifest.elements["uses-permission[@android:name='android.permission.WRITE_EXTERNAL_STORAGE']"]
          #   puts 'Found external permission tag'
          # else
          #   test_manifest.add_element 'uses-permission', {"android:name" => "android.permission.WRITE_EXTERNAL_STORAGE"}
          #   puts 'Added external permission tag'
          # end

          File.open("AndroidManifest.xml", 'w') { |f| test_manifest.document.write(f, 4) }
          instrumentation_property = "test.runner=org.ruboto.test.InstrumentationTestRunner\n"

          # FIXME(uwe): Cleanup when we stop supporting updating apps generated with Android SDK <= 13
          prop_file = %w{ant.properties build.properties}.find { |f| File.exists?(f) }
          prop_lines = File.readlines(prop_file)
          File.open(prop_file, 'a') { |f| f << instrumentation_property } unless prop_lines.include?(instrumentation_property)
          # EMXIF

          ant_setup_line = /^(\s*<\/project>)/
          run_tests_override = <<-EOF
<!-- BEGIN added by ruboto -->

    <macrodef name="run-tests-helper">
      <attribute name="emma.enabled" default="false"/>
      <element name="extra-instrument-args" optional="yes"/>

      <sequential>
        <xpath input="AndroidManifest.xml" expression="/manifest/@package"
                output="manifest.package" />
        <echo>Running tests with failure detection...</echo>
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
            <or>
              <contains string="${tests.output}" substring="INSTRUMENTATION_RESULT"/>
              <contains string="${tests.output}" substring="INSTRUMENTATION_FAILED"/>
              <contains string="${tests.output}" substring="FAILURES"/>
              <not>
                <matches string="${tests.output}" pattern="OK \\(\\d+ tests?\\)" multiline="true"/>
              </not>
            </or>
          </condition>
        </fail>
      </sequential>
    </macrodef>

    <target name="run-tests-quick" description="Runs tests with previously installed packages">
      <run-tests-helper />
    </target>
<!-- END added by ruboto -->

          EOF
          ant_script = File.read('build.xml')
          ant_script.gsub!(/\s*<!-- BEGIN added by ruboto(?:-core)? -->.*?<!-- END added by ruboto(?:-core)? -->\s*/m, '')
          raise "Bad ANT script" unless ant_script.gsub!(ant_setup_line, "#{run_tests_override}\n\n\\1")
          File.open('build.xml', 'w') { |f| f << ant_script }

          # FIXME(uwe): Remove when we stop supporting update from Ruboto < 0.5.3
          if File.directory? 'assets/scripts'
            log_action 'Moving test scripts to the "src" directory.' do
              FileUtils.mv Dir['assets/scripts/*'], 'src'
              FileUtils.rm_rf 'assets/scripts'
            end
          end
          # EMXIF
        end
      end

      def update_jruby(force=nil)
        jruby_core = Dir.glob("libs/jruby-core-*.jar")[0]
        jruby_stdlib = Dir.glob("libs/jruby-stdlib-*.jar")[0]

        unless force
          if !jruby_core || !jruby_stdlib
            puts "Cannot find existing jruby jars in libs. Make sure you're in the root directory of your app."
            return false
          end
        end

        begin
          require 'jruby-jars'
        rescue LoadError
          puts "Could not find the jruby-jars gem.  You need it to include JRuby in your app.  Please install it using\n\n    gem install jruby-jars\n\n"
          return false
        end
        new_jruby_version = JRubyJars::VERSION

        unless force
          current_jruby_version = jruby_core ? jruby_core[16..-5] : "None"
          if current_jruby_version == new_jruby_version
            puts "JRuby is up to date at version #{new_jruby_version}. Make sure you 'gem update jruby-jars' if there is a new version."
            return false
          end

          puts "Current jruby version: #{current_jruby_version}"
          puts "New jruby version: #{new_jruby_version}"
        end

        copier = AssetCopier.new Ruboto::ASSETS, File.expand_path(".")
        log_action("Removing #{jruby_core}") { File.delete *Dir.glob("libs/jruby-core-*.jar") } if jruby_core
        log_action("Removing #{jruby_stdlib}") { File.delete *Dir.glob("libs/jruby-stdlib-*.jar") } if jruby_stdlib
        log_action("Copying #{JRubyJars::core_jar_path} to libs") { copier.copy_from_absolute_path JRubyJars::core_jar_path, "libs" }
        log_action("Copying #{JRubyJars::stdlib_jar_path} to libs") { copier.copy_from_absolute_path JRubyJars::stdlib_jar_path, "libs" }

        # FIXME(uwe):  Try keeping the class count low to enable installation on Android 2.3 devices
        unless new_jruby_version =~ /^1.7.0/ && verify_target_sdk < 15
          log_action("Copying dx.jar to libs") { copier.copy 'libs' }
        end

        reconfigure_jruby_libs(new_jruby_version)

        puts "JRuby version is now: #{new_jruby_version}"
        true
      end

      def update_dexmaker(force=nil)
        jar_file = Dir.glob("libs/dexmaker*.jar")[0]

        # FIXME(uwe):  Skip copying dexmaker to apps using RubotoCore when we include dexmaker.jar in RubotoCore
        return false if !jar_file && !force

        copier = AssetCopier.new Ruboto::ASSETS, File.expand_path(".")
        # FIXME(uwe):  Skip copying dexmaker to apps using RubotoCore when we include dexmaker.jar in RubotoCore
        log_action("Removing #{jar_file}") { File.delete *Dir.glob("libs/dexmaker*.jar") } if jar_file

        # FIXME(uwe):  Try keeping the class count low to enable installation on Android 2.3 devices
        # FIXME(uwe):  Skip copying dexmaker to apps using RubotoCore when we include dexmaker.jar in RubotoCore
        if verify_target_sdk < 15
          log_action("Copying dx.jar to libs") { copier.copy 'libs' }
        end
        # EMXIF
      end

      def update_assets
        puts "\nCopying files:"

        # FIXME(uwe):  Remove when we stop supporting updating from Ruboto < 0.6.0
        if File.exists?('Rakefile') && !File.exists?('rakelib/ruboto.rake')
          FileUtils.rm 'Rakefile'
        end
        # EMXIF

        weak_copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.', false
        %w{.gitignore Rakefile}.each { |f| log_action(f) { weak_copier.copy f } }

        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'
        %w{assets rakelib res/layout test}.each do |f|
          log_action(f) { copier.copy f }
        end
      end

      def update_icons(force = nil)
        log_action('Copying icons') do
          Ruboto::Util::AssetCopier.new(Ruboto::ASSETS, '.', force).copy 'res/drawable/get_ruboto_core.png'
          icon_path = verify_manifest.elements['application'].attributes['android:icon']
          test_icon_path = verify_test_manifest.elements['application'].attributes['android:icon']
          Dir["#{Ruboto::ASSETS}/res/drawable*/ic_launcher.png"].each do |f|
            src_dir = f.slice(/res\/drawable.*\//)
            dest_file = icon_path.sub('@drawable/', src_dir) + '.png'
            if force || !File.exists?(dest_file)
              FileUtils.mkdir_p File.dirname(dest_file)
              FileUtils.cp(f, dest_file)
            end
            test_dest_file = 'test/' + test_icon_path.sub('@drawable/', src_dir) + '.png'
            if force || !File.exists?(test_dest_file)
              FileUtils.mkdir_p File.dirname(test_dest_file)
              FileUtils.cp(f, test_dest_file)
            end
          end
        end
      end

      def update_classes(old_version, force = nil)
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'
        log_action("Ruboto java classes") { copier.copy "src/org/ruboto/*.java" }
        log_action("Ruboto java test classes") { copier.copy "src/org/ruboto/test/*.java", "test" }
        Dir["src/**/*.java"].each do |f|
          source_code = File.read(f)
          if source_code =~ /^\s*package\s+org.ruboto\s*;/
            next
          elsif source_code =~ /public class (.*?) extends org.ruboto.(?:EntryPoint|Ruboto)(Activity|BroadcastReceiver|Service) \{/
            subclass_name, class_name = $1, $2
            puts "Regenerating #{class_name} #{subclass_name}"
            generate_inheriting_file(class_name, subclass_name, verify_package)

            # FIXME(uwe): Remove when we stop supporting upgrading from ruboto 0.7.0 and ruboto 0.8.0
            if (old_version == '0.7.0' || old_version == '0.8.0')
              puts "Ruboto version #{old_version.inspect} detected."
              script_file = File.expand_path("#{SCRIPTS_DIR}/#{underscore(subclass_name)}.rb")
              puts "Adding explicit super call in #{script_file}"
              script_content = File.read(script_file)
              script_content.gsub! /^(\s*)(def on_(?:create\(bundle\)|start|resume|pause|destroy)\n)/, "\\1\\2\\1  super\n"
              File.open(script_file, 'w'){|of| of << script_content}
            end
            # EMXIF

          elsif source_code =~ /^\/\/ Generated Ruboto subclass with method base "(.*?)".*^\s*package\s+(\S+?)\s*;.*public\s+class\s+(\S+?)\s+extends\s+(.*?)\s*(?:implements\s+org.ruboto.RubotoComponent\s*)?\{/m
            method_base, package, subclass_name, class_name = $1, $2, $3, $4
            puts "Regenerating subclass #{package}.#{subclass_name}"
            generate_inheriting_file 'Class', subclass_name
            generate_subclass_or_interface(:package => package, :template => 'InheritingClass', :class => class_name,
                                           :name => subclass_name, :method_base => method_base, :force => force)
          # FIXME(uwe): Remove when we stop updating from Ruboto 0.7.0 and older
          elsif source_code =~ /^\s*package\s+(\S+?)\s*;.*public\s+class\s+(\S+?)\s+extends\s+(.*?)\s\{.*^\s*private Object\[\] callbackProcs = new Object\[\d+\];/m
            package, subclass_name, class_name = $1, $2, $3
            puts "Regenerating subclass #{package}.#{subclass_name}"
            generate_inheriting_file 'Class', subclass_name
            generate_subclass_or_interface(:package => package, :template => 'InheritingClass', :class => class_name,
                                           :name => subclass_name, :method_base => 'on', :force => force)
          # EMXIF
          end
        end
      end

      def update_manifest(min_sdk, target, force = false)
        log_action("\nAdding RubotoActivity, RubotoDialog, RubotoService, and SDK versions to the manifest") do
          if sdk_element = verify_manifest.elements['uses-sdk']
            min_sdk ||= sdk_element.attributes["android:minSdkVersion"]
            target ||= sdk_element.attributes["android:targetSdkVersion"]
          else
            min_sdk ||= MINIMUM_SUPPORTED_SDK_LEVEL
            target ||= MINIMUM_SUPPORTED_SDK_LEVEL
          end

          if min_sdk.to_i < MINIMUM_SUPPORTED_SDK_LEVEL
            min_sdk = MINIMUM_SUPPORTED_SDK_LEVEL
          end

          if target.to_i < MINIMUM_SUPPORTED_SDK_LEVEL
            target = MINIMUM_SUPPORTED_SDK_LEVEL
          end

          app_element = verify_manifest.elements['application']
          app_element.attributes['android:icon'] ||= '@drawable/ic_launcher'

          if min_sdk.to_i >= 11
            app_element.attributes['android:hardwareAccelerated'] ||= 'true'
            app_element.attributes['android:largeHeap'] ||= 'true'
          end

          if !app_element.elements["activity[@android:name='org.ruboto.RubotoActivity']"]
            app_element.add_element 'activity', {"android:name" => "org.ruboto.RubotoActivity", 'android:exported' => 'false'}
          end

          if !app_element.elements["activity[@android:name='org.ruboto.RubotoDialog']"]
            app_element.add_element 'activity', {"android:name" => "org.ruboto.RubotoDialog", 'android:exported' => 'false', "android:theme" => "@android:style/Theme.Dialog"}
          end

          if !app_element.elements["service[@android:name='org.ruboto.RubotoService']"]
            app_element.add_element 'service', {"android:name" => "org.ruboto.RubotoService", 'android:exported' => 'false'}
          end

          if sdk_element
            sdk_element.attributes["android:minSdkVersion"] = min_sdk
            sdk_element.attributes["android:targetSdkVersion"] = target
          else
            verify_manifest.add_element 'uses-sdk', {"android:minSdkVersion" => min_sdk, "android:targetSdkVersion" => target}
          end
          save_manifest
        end
      end

      def update_core_classes(force = nil)
        # FIXME(uwe): Remove when we stop supporting updating from Ruboto 0.5.5 and older.
        FileUtils.rm_rf 'src/org/ruboto/callbacks'
        FileUtils.rm_f 'src/org/ruboto/RubotoView.java'
        # EMXIF

        generate_core_classes(:class => "all", :method_base => "on", :method_include => "", :method_exclude => "", :force => force, :implements => "")
      end

      def read_ruboto_version
        version_file = File.expand_path("./#{SCRIPTS_DIR}/ruboto/version.rb")
        File.read(version_file).slice(/^\s*VERSION = '(.*?)'/, 1) if File.exists?(version_file)
      end

      def update_ruboto(force=nil)
        log_action("Copying ruboto.rb") do
          from = File.expand_path(Ruboto::GEM_ROOT + "/assets/#{SCRIPTS_DIR}/ruboto.rb")
          to = File.expand_path("./#{SCRIPTS_DIR}/ruboto.rb")
          FileUtils.cp from, to
        end
        log_action("Copying ruboto/version.rb") do
          from = File.expand_path(Ruboto::GEM_ROOT + "/lib/ruboto/version.rb")
          to = File.expand_path("./#{SCRIPTS_DIR}/ruboto/version.rb")
          FileUtils.mkdir_p File.dirname(to)
          FileUtils.cp from, to
        end
        log_action("Copying additional ruboto script components") do
          Dir.glob(Ruboto::GEM_ROOT + "/assets/#{SCRIPTS_DIR}/ruboto/**/*.rb").each do |from|
            to = File.expand_path("./#{from.slice /#{SCRIPTS_DIR}\/ruboto\/.*\.rb/}")
            FileUtils.mkdir_p File.dirname(to)
            FileUtils.cp from, to
          end
        end
      end

      def reconfigure_jruby_libs(jruby_core_version)
        reconfigure_jruby_core(jruby_core_version)
        reconfigure_jruby_stdlib
      end

      # - Removes unneeded code from jruby-core
      # - Split into smaller jars that can be used separately
      def reconfigure_jruby_core(jruby_core_version)
        jruby_core = JRubyJars::core_jar_path.split('/')[-1]
        Dir.chdir 'libs' do
          log_action("Removing unneeded classes from #{jruby_core}") do
            FileUtils.rm_rf 'tmp'
            Dir.mkdir 'tmp'
            Dir.chdir 'tmp' do
              FileUtils.move "../#{jruby_core}", "."
              `jar -xf #{jruby_core}`
              File.delete jruby_core
              if jruby_core_version >= '1.7.0'
                excluded_core_packages = [
                    'META-INF', 'cext',
                    # 'com/headius', included since we are trying to use DexClient
                    'com/headius/invokebinder',
                    'com/kenai/constantine', 'com/kenai/jffi', 'com/martiansoftware', 'ext', 'java',
                    'jline', 'jni',
                    'jnr/constants/platform/darwin', 'jnr/constants/platform/fake', 'jnr/constants/platform/freebsd',
                    'jnr/constants/platform/openbsd', 'jnr/constants/platform/sunos', 'jnr/constants/platform/windows',
                    'jnr/ffi/annotations', 'jnr/ffi/byref', 'jnr/ffi/provider', 'jnr/ffi/util',
                    'jnr/ffi/posix/util',
                    'org/apache',
                    'org/bouncycastle', # TODO(uwe): Issue #154 Add back when we add jruby-openssl.  The bouncycastle included in Android is cripled.
                    'org/jruby/ant',
                    'org/jruby/cext',
                    # 'org/jruby/compiler',      # Needed for initialization, but shoud not be necessary
                    # 'org/jruby/compiler/impl', # Needed for initialization, but shoud not be necessary
                    'org/jruby/compiler/util',
                    'org/jruby/demo',
                    'org/jruby/embed/bsf',
                    'org/jruby/embed/jsr223',
                    'org/jruby/embed/osgi',
                    # 'org/jruby/ext/ffi', # Used by several JRuby core classes, but should not be needed unless we add FFI support
                    'org/jruby/ext/ffi/io',
                    'org/jruby/ext/ffi/jffi',
                    'org/jruby/ext/openssl', # TODO(uwe): Issue #154 Add back when we add jruby-openssl.

                    # FIXME(uwe):  IR is the future.  We should try using it.
                    # 'org/jruby/ir',
                    # 'org/jruby/ir/dataflow',
                    # 'org/jruby/ir/instructions',
                    # 'org/jruby/ir/interpreter',
                    # 'org/jruby/ir/operands',
                    # 'org/jruby/ir/passes',
                    # 'org/jruby/ir/representations',
                    # 'org/jruby/ir/targets',
                    # 'org/jruby/ir/transformations',
                    # 'org/jruby/ir/util',

                    'org/jruby/javasupport/bsf',
                    'org/jruby/runtime/invokedynamic',
                ]

                # TODO(uwe): Remove when we stop supporting jruby-jars < 1.7.0
              else
                print 'Retaining com.kenai.constantine and removing jnr for JRuby < 1.7.0...'
                excluded_core_packages = [
                    'META-INF', 'cext',
                    'com/kenai/jffi', 'com/martiansoftware', 'ext', 'java',
                    'jline', 'jni',
                    'jnr',
                    'jnr/constants/platform/darwin', 'jnr/constants/platform/fake', 'jnr/constants/platform/freebsd',
                    'jnr/constants/platform/openbsd', 'jnr/constants/platform/sunos', 'jnr/constants/platform/windows',
                    'jnr/ffi/annotations', 'jnr/ffi/byref', 'jnr/ffi/provider', 'jnr/ffi/util',
                    'jnr/netdb', 'jnr/ffi/posix/util',
                    'org/apache', 'org/jruby/ant',
                    'org/jruby/compiler/ir',
                    'org/jruby/compiler/util',
                    'org/jruby/demo', 'org/jruby/embed/bsf',
                    'org/jruby/embed/jsr223', 'org/jruby/embed/osgi', 'org/jruby/ext/ffi', 'org/jruby/javasupport/bsf',
                    'org/jruby/runtime/invokedynamic',
                ]
                # ODOT
              end

              excluded_core_packages.each do |i|
                FileUtils.remove_dir(i, true) rescue puts "Failed to remove package: #{i} (#{$!})"
              end

              # FIXME(uwe):  Add a Ruboto.yml config for this if it works
              # Reduces the installation footprint, but also reduces performance and stack usage
              # FIXME(uwe):  Measure the performance change
              if false && jruby_core_version =~ /^1.7.0/ && Dir.chdir('../..'){verify_target_sdk < 15}
                invokers = Dir['**/*${INVOKER$*,POPULATOR}.class']
                log_action("Removing invokers & populators(#{invokers.size})") do
                  FileUtils.rm invokers
                end
              end

              # Uncomment this section to get a jar for each top level package in the core
              #Dir['**/*'].select{|f| !File.directory?(f)}.map{|f| File.dirname(f)}.uniq.sort.reverse.each do |dir|
              #  `jar -cf ../jruby-core-#{dir.gsub('/', '.')}-#{jruby_core_version}.jar #{dir}`
              #  FileUtils.rm_rf dir
              #end

              # Add our proxy class factory
              `javac -source 1.6 -target 1.6 -cp .:#{Ruboto::ASSETS}/libs/dx.jar:#{Ruboto::ASSETS}/libs/dexmaker20120305.jar:#{Dir["#{Ruboto::SdkVersions::ANDROID_HOME}/platforms/android-*/android.jar"][0]} -d . #{Ruboto::GEM_ROOT}/lib/*.java`
              raise "Compile failed" unless $? == 0

              `jar -cf ../#{jruby_core} .`
            end
            FileUtils.remove_dir "tmp", true
          end
        end
      end

      # - Moves ruby stdlib to the root of the jruby-stdlib jar
      def reconfigure_jruby_stdlib
        excluded_stdlibs = [*verify_ruboto_config[:excluded_stdlibs]].compact
        Dir.chdir 'libs' do
          jruby_stdlib = JRubyJars::stdlib_jar_path.split('/')[-1]
          log_action("Reformatting #{jruby_stdlib}") do
            FileUtils.mkdir_p 'tmp'
            Dir.chdir 'tmp' do
              FileUtils.mkdir_p 'old'
              FileUtils.mkdir_p 'new'
              Dir.chdir 'old' do
                `jar -xf ../../#{jruby_stdlib}`
              end
              FileUtils.move 'old/META-INF/jruby.home/lib', 'new'

              FileUtils.rm_rf 'new/lib/ruby/gems'

              if excluded_stdlibs.any?

                # TODO(uwe): Simplify when we stop supporting JRuby < 1.7.0
                raise "Unrecognized JRuby stdlib jar: #{jruby_stdlib}" unless jruby_stdlib =~ /jruby-stdlib-(.*).jar/
                jruby_version = Gem::Version.new($1)
                if Gem::Requirement.new('< 1.7.0.preview1') =~ jruby_version
                  lib_dirs = ['1.8', '1.9', 'site_ruby/1.8', 'site_ruby/1.9', 'site_ruby/shared']
                else
                  lib_dirs = ['1.8', '1.9', 'shared']
                end
                # TODO end

                lib_dirs.each do |ld|
                  excluded_stdlibs.each do |d|
                    dir = "new/lib/ruby/#{ld}/#{d}"
                    FileUtils.rm_rf dir if File.exists? dir
                    file = "#{dir}.rb"
                    FileUtils.rm_rf file if File.exists? file
                  end
                end
                print "excluded #{excluded_stdlibs.join(' ')}..."
              end

              Dir.chdir "new" do
                # Uncomment this part to split the stdlib into one jar per directory
                # Dir['*'].select{|f| File.directory? f}.each do |d|
                #    `jar -cf ../jruby-stdlib-#{d}-#{JRubyJars::VERSION}.jar #{d}`
                #    FileUtils.rm_rf d
                # end

                `jar -cf ../../#{jruby_stdlib} .`
              end
            end
          end

          FileUtils.remove_dir "tmp", true
        end
      end

      def update_bundle
        if File.exist?('Gemfile.apk') && File.exists?('libs/bundle.jar')
          FileUtils.rm 'libs/bundle.jar'
          system 'rake bundle'
        end
      end

    end
  end
end
