require 'ruboto/version'
require 'ruboto/core_ext/rexml'
require 'ruboto/sdk_locations'
require 'ruboto/util/build'

module Ruboto
  module Util
    module Update
      include Build
      include Ruboto::SdkVersions
      include Ruboto::SdkLocations

      ###########################################################################
      #
      # Updating components
      #
      def update_android
        root = Dir.getwd
        build_xml_file = "#{root}/build.xml"
        name = REXML::Document.new(File.read(build_xml_file)).root.attributes['name']

        prop_file = "#{root}/project.properties"
        version_regexp = /^(target=android-)(\d+)$/
        if (project_property_file = File.read(prop_file)) =~ version_regexp
          if $2.to_i < MINIMUM_SUPPORTED_SDK_LEVEL
            puts "Upgrading project to target #{MINIMUM_SUPPORTED_SDK}"
            File.open(prop_file, 'w') { |f| f << project_property_file.gsub(version_regexp, "\\1#{MINIMUM_SUPPORTED_SDK_LEVEL}") }
          end
        end

        system "android update project -p #{root} -n #{name} --subprojects"
        raise "android update project failed with return code #{$?}" unless $? == 0
      end

      def update_test(force = nil)
        root = Dir.getwd
        if !File.exists?("#{root}/test") || !File.exists?("#{root}/test/AndroidManifest.xml") || !File.exists?("#{root}/test/ant.properties")
          name = verify_strings.root.elements['string'].text.gsub(' ', '')
          puts "\nGenerating Android test project #{name} in #{root}..."
          system %Q{android create test-project -m "#{root.gsub('"', '\"')}" -n "#{name}Test" -p "#{root.gsub('"', '\"')}/test"}
          FileUtils.rm_rf File.join(root, 'test', 'src', verify_package.split('.'))
          puts 'Done'
        end

        Dir.chdir File.join(root, 'test') do
          instrumentation_property = "test.runner=org.ruboto.test.InstrumentationTestRunner\n"
          prop_file = 'ant.properties'
          prop_lines = (prop_lines_org = File.read(prop_file)).dup
          prop_lines.gsub!(/^tested.project.dir=.*$/, 'tested.project.dir=../')
          prop_lines << instrumentation_property unless prop_lines.include? instrumentation_property
          if prop_lines != prop_lines_org
            File.open(prop_file, 'w') { |f| f << prop_lines }
          end

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

          File.open('AndroidManifest.xml', 'w') { |f| REXML::Formatters::OrderedAttributes.new(4).write(test_manifest.document, f) }

          run_tests_override = <<-EOF
<!-- BEGIN added by Ruboto -->

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
<!-- END added by Ruboto -->
          EOF
          ant_script = File.read('build.xml')

          # FIXME(uwe): Remove when we stop support for updating from Ruboto 0.8.1 and older
          ant_script.gsub!(/\s*<!-- BEGIN added by ruboto(?:-core)? -->.*?<!-- END added by ruboto(?:-core)? -->\s*/m, '')
          # EMXIF

          ant_script.gsub!(/\s*<!-- BEGIN added by Ruboto -->.*?<!-- END added by Ruboto -->\s*/m, '')
          raise 'Bad ANT script' unless ant_script.gsub!(/\s*(<\/project>)/, "\n\n#{run_tests_override}\n\n\\1")
          File.open('build.xml', 'w') { |f| f << ant_script }
        end
      end

      def update_jruby(force=nil, explicit = false)
        installed_jruby_core = Dir.glob('libs/jruby-core-*.jar')[0]
        installed_jruby_stdlib = Dir.glob('libs/jruby-stdlib-*.jar')[0]

        unless force
          if !installed_jruby_core || !installed_jruby_stdlib
            puts "Cannot find existing jruby jars in libs. Make sure you're in the root directory of your app." if explicit
            return false
          end
        end

        install_jruby_jars_gem
        begin
          require 'jruby-jars'
        rescue LoadError
          puts "Could not find the jruby-jars gem.  You need it to include JRuby in your app.  Please install it using\n\n    gem install jruby-jars\n\n"
          return false
        end
        new_jruby_version = JRubyJars::VERSION

        unless force
          current_jruby_version = installed_jruby_core ? installed_jruby_core[16..-5] : 'None'
          if current_jruby_version == new_jruby_version
            puts "JRuby is up to date at version #{new_jruby_version}. Make sure you 'gem update jruby-jars' if there is a new version."
            return false
          end

          puts "Current jruby version: #{current_jruby_version}"
          puts "New jruby version: #{new_jruby_version}"
        end

        copier = AssetCopier.new Ruboto::ASSETS, File.expand_path('.')
        log_action("Removing #{installed_jruby_core}") { File.delete *Dir.glob('libs/jruby-core-*.jar') } if installed_jruby_core
        log_action("Removing #{installed_jruby_stdlib}") { File.delete *Dir.glob('libs/jruby-stdlib-*.jar') } if installed_jruby_stdlib
        log_action("Copying #{JRubyJars::core_jar_path} to libs") { FileUtils.cp JRubyJars::core_jar_path, "libs/jruby-core-#{new_jruby_version}.jar" }
        log_action("Copying #{JRubyJars::stdlib_jar_path} to libs") { FileUtils.cp JRubyJars::stdlib_jar_path, "libs/jruby-stdlib-#{new_jruby_version}.jar" }

        unless File.read('project.properties') =~ /^dex.force.jumbo=/
          log_action('Setting JUMBO dex file format') do
            File.open('project.properties', 'a') { |f| f << "dex.force.jumbo=true\n" }
          end
        end

        log_action('Copying dx.jar to libs') do
          copier.copy 'libs'
        end

        reconfigure_jruby_libs(new_jruby_version)

        puts "JRuby version is now: #{new_jruby_version}"
        true
      end

      def install_jruby_jars_gem
        if (jars_version_from_env = ENV['JRUBY_JARS_VERSION'])
          version_requirement = " -v #{jars_version_from_env}"
        end
        `gem query -i -n jruby-jars#{version_requirement}`
        unless $? == 0
          local_gem_dir = ENV['LOCAL_GEM_DIR'] || Dir.getwd
          local_gem_file = "#{local_gem_dir}/jruby-jars-#{jars_version_from_env}.gem"
          if File.exists?(local_gem_file)
            system "gem install -l #{local_gem_file} --no-ri --no-rdoc"
          else
            system "gem install -r jruby-jars#{version_requirement} --no-ri --no-rdoc"
          end
        end
        raise "install of jruby-jars failed with return code #$?" unless $? == 0
        if jars_version_from_env
          exclusion_clause = %Q{-v "!=#{jars_version_from_env}"}
          `gem query -i -n jruby-jars #{exclusion_clause}`
          if $? == 0
            system %Q{gem uninstall jruby-jars --all #{exclusion_clause}}
            raise "Uninstall of jruby-jars failed with return code #$?" unless $? == 0
          end
        end
        Gem.refresh
      end

      def update_dx_jar(force=nil)
        # FIXME(uwe): Remove when we stop updating from Ruboto 0.8.1 and older.
        FileUtils.rm(Dir['libs/dexmaker*.jar'])
        # EMXIF

        jar_file = Dir.glob('libs/dx.jar')[0]

        # FIXME(uwe): Remove when we stop updating from Ruboto 0.10.0 and older.
        jruby_present = !!Dir.glob('libs/jruby-core-*.jar')[0]
        log_action("Removing #{jar_file}") { File.delete jar_file } if jar_file && !jruby_present
        # EMXIF

        return if !jar_file && !force

        copier = AssetCopier.new Ruboto::ASSETS, File.expand_path('.')
        log_action('Copying dx.jar to libs') { copier.copy 'libs' }
      end

      def update_assets
        puts "\nCopying files:"
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
        log_action('Ruboto java classes') { copier.copy 'src/org/ruboto/*.java' }
        log_action('Ruboto java test classes') { copier.copy 'src/org/ruboto/test/*.java', 'test' }
        Dir['src/**/*.java'].each do |f|
          source_code = File.read(f)
          if source_code =~ /^\s*package\s+org.ruboto\s*;/
            next
          elsif source_code =~ /public class (.*?) extends org.ruboto.(?:EntryPoint|Ruboto)(Activity|BroadcastReceiver|Service) \{/
            subclass_name, class_name = $1, $2
            puts "Regenerating #{class_name} #{subclass_name}"
            generate_inheriting_file(class_name, subclass_name, verify_package)

            # FIXME(uwe): Remove when we stop supporting upgrading from ruboto 0.7.0 and ruboto 0.8.0
            if old_version == '0.7.0' || old_version == '0.8.0'
              puts "Ruboto version #{old_version.inspect} detected."
              script_file = File.expand_path("#{SCRIPTS_DIR}/#{underscore(subclass_name)}.rb")
              puts "Adding explicit super call in #{script_file}"
              script_content = File.read(script_file)
              script_content.gsub! /^(\s*)(def on_(?:create\(bundle\)|start|resume|pause|destroy)\n)/, "\\1\\2\\1  super\n"
              File.open(script_file, 'w') { |of| of << script_content }
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
          if (sdk_element = verify_manifest.elements['uses-sdk'])
            min_sdk ||= sdk_element.attributes['android:minSdkVersion']
            target ||= sdk_element.attributes['android:targetSdkVersion']
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

          unless app_element.elements["activity[@android:name='org.ruboto.RubotoActivity']"]
            app_element.add_element 'activity', {'android:name' => 'org.ruboto.RubotoActivity', 'android:exported' => 'false'}
          end

          unless app_element.elements["activity[@android:name='org.ruboto.SplashActivity']"]
            app_element.add_element 'activity', {'android:name' => 'org.ruboto.SplashActivity', 'android:exported' => 'false', 'android:configChanges' => (target.to_i >= 13 ? 'orientation|screenSize' : 'orientation'), 'android:noHistory' => 'true'}
          end

          unless app_element.elements["activity[@android:name='org.ruboto.RubotoDialog']"]
            app_element.add_element 'activity', {'android:name' => 'org.ruboto.RubotoDialog', 'android:exported' => 'false', 'android:theme' => '@android:style/Theme.Dialog'}
          end

          unless app_element.elements["service[@android:name='org.ruboto.RubotoService']"]
            app_element.add_element 'service', {'android:name' => 'org.ruboto.RubotoService', 'android:exported' => 'false'}
          end

          if sdk_element
            sdk_element.attributes['android:minSdkVersion'] = min_sdk
            sdk_element.attributes['android:targetSdkVersion'] = target
          else
            verify_manifest.add_element 'uses-sdk', {'android:minSdkVersion' => min_sdk, 'android:targetSdkVersion' => target}
          end
          save_manifest
        end
      end

      def update_core_classes(force = nil)
        generate_core_classes(:class => 'all', :method_base => 'on', :method_include => '', :method_exclude => '', :force => force, :implements => '')
      end

      def read_ruboto_version
        version_file = File.expand_path("./#{SCRIPTS_DIR}/ruboto/version.rb")
        File.read(version_file).slice(/^\s*VERSION = '(.*?)'/, 1) if File.exists?(version_file)
      end

      def update_ruboto(force=nil)
        source_files_pattern = 'ruboto{.rb,/**/*}'
        new_sources_dir = Ruboto::GEM_ROOT + "/assets/#{SCRIPTS_DIR}"
        new_sources = Dir.chdir(new_sources_dir) { Dir[source_files_pattern] }.
            select { |f| !(File.directory?("#{new_sources_dir}/#{f}") || File.basename(f) == '.' || File.basename(f) == '..') }
        old_sources = Dir.chdir("#{SCRIPTS_DIR}") { Dir[source_files_pattern] }.
            select { |f| !(File.directory?("#{SCRIPTS_DIR}/#{f}") || File.basename(f) == '.' || File.basename(f) == '..') }
        obsolete_sources = old_sources - new_sources - %w(ruboto/version.rb)
        obsolete_sources.each do |f|
          log_action("Deleting obsolete script #{f}") do
            FileUtils.rm_f f
          end
        end
        log_action('Copying ruboto/version.rb') do
          from = File.expand_path(Ruboto::GEM_ROOT + '/lib/ruboto/version.rb')
          to = File.expand_path("./#{SCRIPTS_DIR}/ruboto/version.rb")
          FileUtils.mkdir_p File.dirname(to)
          FileUtils.cp from, to
        end
        log_action('Copying additional ruboto script components') do
          new_sources.each do |from|
            to = File.expand_path(from, SCRIPTS_DIR)
            FileUtils.mkdir_p File.dirname(to)
            FileUtils.cp "#{new_sources_dir}/#{from}", to
          end
        end
      end

      def reconfigure_jruby_libs(jruby_core_version)
        reconfigure_jruby_core(jruby_core_version)
        reconfigure_jruby_stdlib
        reconfigure_dx_jar
      end

      # - Removes unneeded code from jruby-core
      # - Split into smaller jars that can be used separately
      def reconfigure_jruby_core(jruby_core_version)
        Dir.chdir 'libs' do
          jruby_core = Dir['jruby-core-*.jar'][-1]
          log_action("Removing unneeded classes from #{jruby_core}") do
            FileUtils.rm_rf 'tmp'
            Dir.mkdir 'tmp'
            Dir.chdir 'tmp' do
              FileUtils.move "../#{jruby_core}", '.'
              `jar -xf #{jruby_core}`
              raise "Unpacking jruby-core jar failed: #$?" unless $? == 0
              File.delete jruby_core
              if Gem::Version.new(jruby_core_version) >= Gem::Version.new('9000.dev')
                #noinspection RubyLiteralArrayInspection
                excluded_core_packages = [
                    '**/*Darwin*',
                    '**/*Solaris*',
                    '**/*windows*',
                    '**/*Windows*',
                    'META-INF',
                    'com/headius',
                    'com/kenai/constantine',
                    'com/kenai/jffi',
                    'com/kenai/jnr/x86asm',
                    'com/martiansoftware',
                    'jni',
                    'jnr/constants/platform/darwin',
                    'jnr/constants/platform/fake',
                    'jnr/constants/platform/freebsd',
                    'jnr/constants/platform/openbsd',
                    'jnr/constants/platform/sunos',
                    'jnr/ffi/annotations',
                    'jnr/ffi/byref',
                    'jnr/ffi/mapper',
                    'jnr/ffi/provider',
                    'jnr/ffi/util',
                    'jnr/ffi/Struct$*',
                    'jnr/ffi/types',
                    'jnr/posix/Aix*',
                    'jnr/posix/FreeBSD*',
                    'jnr/posix/MacOS*',
                    'jnr/posix/OpenBSD*',
                    'jnr/x86asm',
                    'org/jruby/ant',
                    'org/jruby/cext',
                    # 'org/jruby/compiler',      # Needed for initialization, but should not be necessary
                    # 'org/jruby/compiler/impl', # Needed for initialization, but should not be necessary
                    'org/jruby/compiler/impl/BaseBodyCompiler*',
                    'org/jruby/compiler/util',
                    'org/jruby/demo',
                    'org/jruby/embed/bsf',
                    'org/jruby/embed/jsr223',
                    'org/jruby/embed/osgi',
                    # 'org/jruby/ext/ffi', # Used by several JRuby core classes, but should not be needed unless we add FFI support
                    'org/jruby/ext/ffi/AbstractMemory*',
                    'org/jruby/ext/ffi/io',
                    'org/jruby/ext/ffi/jffi',
                    # 'org/jruby/ext/tracepoint',
                    'org/jruby/javasupport/bsf',
                    # 'org/jruby/management', # should be excluded
                    # 'org/jruby/runtime/invokedynamic', # Should be excluded
                    # 'org/jruby/runtime/opto',              # What is this?
                    # 'org/jruby/runtime/opto/OptoFactory*', # What is this?
                    'org/yecht',
                ]
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.5')
                excluded_core_packages = %w(**/*Darwin* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/kenai/jnr/x86asm com/martiansoftware jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/mapper jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/Aix* jnr/posix/FreeBSD* jnr/posix/MacOS* jnr/posix/OpenBSD* jnr/x86asm org/jruby/ant org/jruby/cext org/jruby/compiler/impl/BaseBodyCompiler* org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/AbstractMemory* org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/ext/tracepoint org/jruby/javasupport/bsf org/yecht)
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.4')
                excluded_core_packages = %w(**/*Darwin* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/kenai/jnr/x86asm com/martiansoftware jline jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/mapper jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/Aix* jnr/posix/FreeBSD* jnr/posix/MacOS* jnr/posix/OpenBSD* jnr/x86asm org/apache org/fusesource org/jruby/ant org/jruby/cext org/jruby/compiler/impl/BaseBodyCompiler* org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/AbstractMemory* org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/ext/ripper org/jruby/ext/tracepoint org/jruby/javasupport/bsf org/yecht)
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.3')
                excluded_core_packages = %w(**/*Darwin* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/kenai/jnr/x86asm com/martiansoftware jline jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/FreeBSD* jnr/posix/MacOS* jnr/posix/OpenBSD* jnr/x86asm org/apache org/fusesource org/jruby/ant org/jruby/cext org/jruby/compiler/impl/BaseBodyCompiler* org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/AbstractMemory* org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/javasupport/bsf org/yecht)
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.2')
                excluded_core_packages = %w(**/*Darwin* **/*Ruby20* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/martiansoftware jline jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/MacOS* jnr/posix/OpenBSD* org/apache org/fusesource org/jruby/ant org/jruby/cext org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/javasupport/bsf)
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.1')
                excluded_core_packages = %w(**/*Darwin* **/*Ruby20* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/martiansoftware jline jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/MacOS* jnr/posix/OpenBSD* org/apache org/fusesource org/jruby/ant org/jruby/cext org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/ext/openssl org/jruby/javasupport/bsf org/jruby/org/bouncycastle)
              elsif Gem::Version.new(jruby_core_version) >= Gem::Version.new('1.7.0')
                # TODO(uwe): Remove when we stop supporting jruby-jars 1.7.0
                excluded_core_packages = %w(**/*Darwin* **/*Solaris* **/*windows* **/*Windows* META-INF com/headius com/kenai/constantine com/kenai/jffi com/martiansoftware jline jni jnr/constants/platform/darwin jnr/constants/platform/fake jnr/constants/platform/freebsd jnr/constants/platform/openbsd jnr/constants/platform/sunos jnr/ffi/annotations jnr/ffi/byref jnr/ffi/provider jnr/ffi/util jnr/ffi/Struct$* jnr/ffi/types jnr/posix/MacOS* jnr/posix/OpenBSD* org/apache org/bouncycastle org/fusesource org/jruby/ant org/jruby/cext org/jruby/compiler/util org/jruby/demo org/jruby/embed/bsf org/jruby/embed/jsr223 org/jruby/embed/osgi org/jruby/ext/ffi/io org/jruby/ext/ffi/jffi org/jruby/ext/openssl org/jruby/javasupport/bsf)
                # ODOT
              else
                raise "Unsupported JRuby version: #{jruby_core_version.inspect}."
              end

              excluded_core_packages.each do |i|
                if File.directory? i
                  FileUtils.remove_dir(i, true) rescue puts "Failed to remove package: #{i} (#{$!})"
                elsif Dir[i].each { |f| FileUtils.rm_rf f }.empty?
                  print "exclude pattern #{i.inspect} found no files..."
                end
              end

              # FIXME(uwe):  Add a Ruboto.yml config for this if it works
              # Reduces the installation footprint, but also reduces performance and increases stack
              # FIXME(uwe):  Measure the performance change
              if ENV['STRIP_INVOKERS']
                invokers = Dir['**/*$INVOKER$*.class']
                if invokers.size > 0
                  print "Removing invokers(#{invokers.size})..."
                  FileUtils.rm invokers
                end
                populators = Dir['**/*$POPULATOR.class']
                if populators.size > 0
                  print "Removing populators(#{populators.size})..."
                  FileUtils.rm populators
                end
              end

              # Uncomment this section to get a jar for each top level package in the core
              #Dir['**/*'].select{|f| !File.directory?(f)}.map{|f| File.dirname(f)}.uniq.sort.reverse.each do |dir|
              #  `jar -cf ../jruby-core-#{dir.gsub('/', '.')}-#{jruby_core_version}.jar #{dir}`
              #  FileUtils.rm_rf dir
              #end

              # Add our proxy class factory
              android_jar = Dir["#{ANDROID_HOME.gsub("\\", '/')}/platforms/*/android.jar"][0]
              unless android_jar
                puts
                puts '*' * 80
                puts "    Could not find any Android platforms in #{ANDROID_HOME}/platforms."
                puts '    At least one Android Platform SDK must be installed to compile the Ruboto classes.'
                puts '    Please install an Android Platform SDK using the "android" package manager.'
                puts '*' * 80
                puts
                exit 1
              end
              android_jar.gsub!(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
              class_path = ['.', "#{Ruboto::ASSETS}/libs/dx.jar"].join(File::PATH_SEPARATOR).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
              sources = "#{Ruboto::GEM_ROOT}/lib/*.java".gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
              `javac -source 1.6 -target 1.6 -cp #{class_path} -bootclasspath #{android_jar} -d . #{sources}`
              raise 'Compile failed' unless $? == 0

              `jar -cf ..#{File::ALT_SEPARATOR || File::SEPARATOR}#{jruby_core} .`
              raise "Creating repackaged jruby-core jar failed: #$?" unless $? == 0
            end
            FileUtils.remove_dir 'tmp', true
          end
        end
      end

      # - Moves ruby stdlib to the root of the jruby-stdlib jar
      def reconfigure_jruby_stdlib
        min_sdk_version = verify_manifest.elements['uses-sdk'].attributes['android:minSdkVersion'].to_i
        included_stdlibs = verify_ruboto_config[:included_stdlibs]
        excluded_stdlibs = [*verify_ruboto_config[:excluded_stdlibs]].compact
        Dir.chdir 'libs' do
          jruby_stdlib = Dir['jruby-stdlib-*.jar'][-1]
          log_action("Reformatting #{jruby_stdlib}") do
            FileUtils.mkdir_p 'tmp'
            Dir.chdir 'tmp' do
              FileUtils.mkdir_p 'old'
              FileUtils.mkdir_p 'new/jruby.home'
              Dir.chdir 'old' do
                `jar -xf ../../#{jruby_stdlib}`
                raise "Unpacking jruby-stdlib jar failed: #$?" unless $? == 0
              end
              FileUtils.move 'old/META-INF/jruby.home/lib', 'new/jruby.home/lib'
              FileUtils.rm_rf 'new/jruby.home/lib/ruby/gems'

              jruby_stdlib_version = Gem::Version.new(JRubyJars::VERSION)

              if included_stdlibs
                lib_dirs = %w(1.8 1.9 2.0 shared)

                # FIXME(uwe): Remove when we stop testing JRuby < 1.7.4.dev
                lib_dirs.delete('2.0') if jruby_stdlib_version < Gem::Version.new('1.7.4.dev')
                # EMXIF

                print 'excluded...'
                lib_dirs.each do |ld|
                  Dir.chdir "new/jruby.home/lib/ruby/#{ld}" do
                    libs = Dir['*'].map { |d| d.sub /\.(rb|jar)$/, '' }.uniq
                    libs.each do |d|
                      next if included_stdlibs.include? d
                      FileUtils.rm_rf d if File.exists? d
                      file = "#{d}.rb"
                      FileUtils.rm_rf file if File.exists? file
                      jarfile = "#{d}.jar"
                      FileUtils.rm_rf jarfile if File.exists? jarfile
                      print "#{d}..."
                    end
                  end
                end
              end

              if excluded_stdlibs.any?
                %w(1.8 1.9 2.0 shared).each do |ld|
                  # FIXME(uwe): Remove when we stop testing JRuby < 1.7.4.dev
                  next if ld == '2.0' && jruby_stdlib_version < Gem::Version.new('1.7.4.dev')
                  # EMXIF
                  excluded_stdlibs.each do |d|
                    dir = "new/jruby.home/lib/ruby/#{ld}/#{d}"
                    FileUtils.rm_rf dir if File.exists? dir
                    file = "#{dir}.rb"
                    FileUtils.rm_rf file if File.exists? file
                  end
                end
                print "excluded #{excluded_stdlibs.join(' ')}..."
              end

              Dir.chdir 'new' do
                Dir['**/*.jar'].each do |j|

                  # FIXME(uwe):  Installing bcmail-jdk15-146.jar + bcprov-jdk15-146.jar fails due to
                  # http://code.google.com/p/android/issues/detail?id=40409
                  # This breaks ssl and https. Remove when we stop supporting JRuby <= 1.7.2
                  if j =~ /bcmail|bcprov-jdk15-146/
                    FileUtils.rm j
                    next
                  end
                  # EMXIF

                  # FIXME(uwe): Adding the jars triggers the "LinearAlloc exceeded capacity"
                  # bug in Android 2.3.  Remove when we stop supporting android-10 and older
                  if min_sdk_version <= 10
                    FileUtils.rm j
                    next
                  end
                  # EMXIF

                  # FIXME(uwe): These should be included but break the 64K method count limit
                  if j =~ /bcpkix-jdk15on-1\.?47|bcprov-jdk15on-1\.?47|jopenssl|kryptcore|kryptproviderjdk/
                    FileUtils.rm j
                    next
                  end
                  # EMXIF

                  print "#{File.basename(j).chomp('.jar')}..."
                  system "jar xf #{j}"
                  FileUtils.rm j
                  if ENV['STRIP_INVOKERS']
                    invokers = Dir['**/*$INVOKER$*.class']
                    if invokers.size > 0
                      print "Removing invokers(#{invokers.size})..."
                      FileUtils.rm invokers
                    end
                    populators = Dir['**/*$POPULATOR.class']
                    if populators.size > 0
                      print "Removing populators(#{populators.size})..."
                      FileUtils.rm populators
                    end
                  end

                  if j =~ %r{json/ext/generator.jar$}
                    jar_load_code = <<-END_CODE
        require 'jruby'
        puts 'Starting JSON Generator Service'
        public
        Java::json.ext.GeneratorService.new.basicLoad(JRuby.runtime)
                    END_CODE
                  elsif j =~ %r{json/ext/parser.jar$}
                    jar_load_code = <<-END_CODE
        require 'jruby'
        puts 'Starting JSON Parser Service'
        public
        Java::json.ext.ParserService.new.basicLoad(JRuby.runtime)
                    END_CODE
                  else
                    jar_load_code = ''
                  end

                  File.open("#{j}.rb", 'w') { |f| f << jar_load_code }
                  File.open("#{j}.jar.rb", 'w') { |f| f << jar_load_code }
                end

                `jar -cf ../../#{jruby_stdlib} .`
                raise "Creating repackaged jruby-stdlib jar failed: #$?" unless $? == 0
              end
            end
          end

          FileUtils.remove_dir 'tmp', true
        end
      end

      # - Removes unneeded code from dx.jar
      def reconfigure_dx_jar
        dx_jar = 'dx.jar'
        Dir.chdir 'libs' do
          log_action("Removing unneeded classes from #{dx_jar}") do
            FileUtils.rm_rf 'tmp'
            Dir.mkdir 'tmp'
            Dir.chdir 'tmp' do
              FileUtils.move "../#{dx_jar}", '.'
              `jar -xf #{dx_jar}`
              raise "Unpacking dx.jar jar failed: #$?" unless $? == 0
              File.delete dx_jar
              #noinspection RubyLiteralArrayInspection
              excluded_core_packages = [
                  'com/android/dx/command',
                  # 'com/android/dx/ssa', # Tests run OK without this package, but we may loose some optimizations.
                  'junit',
              ]
              excluded_core_packages.each do |i|
                FileUtils.remove_dir(i, true) rescue puts "Failed to remove package: #{i} (#{$!})"
              end
              `jar -cf ../#{dx_jar} .`
              raise "Creating repackaged dx.jar failed: #$?" unless $? == 0
            end
            FileUtils.remove_dir 'tmp', true
          end
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
