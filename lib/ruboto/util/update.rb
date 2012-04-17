module Ruboto
  module Util
    module Update
      include Build
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
        # FIXME(uwe): Needed when updating from Android SDK <= 13 to 14
        # FIXME(uwe): Remove when we stop supporting upgrading from Android SDK <= 13
        if File.read(build_xml_file) !~ /<!-- version-tag: 1 -->/
          puts "Forcing generation of new build.xml since upgrading a project generated with Android SDK 13 or older."
          FileUtils.rm_f build_xml_file
        end
        # FIXME end

        # FIXME(uwe):  Simplify when we stop supporting upgrading from Android ASK <= 13
        prop_file = File.exists?(new_prop_file) ? new_prop_file : old_prop_file
        version_regexp = /^(target=android-)(\d+)$/
        if (project_property_file = File.read(prop_file)) =~ version_regexp
          if $2.to_i < MINIMUM_SUPPORTED_SDK_LEVEL
            puts "Upgrading project to target #{MINIMUM_SUPPORTED_SDK}"
            File.open(prop_file, 'w'){|f| f << project_property_file.gsub(version_regexp, "\\1#{MINIMUM_SUPPORTED_SDK_LEVEL}")}
          end
        end
        # FIXME end

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
          # FIXME(uwe): Needed when updating from Android SDK <=13 to 14
          FileUtils.rm_f "#{root}/test/build.xml"
          # FIXME end

          puts "\nUpdating Android test project #{name} in #{root}/test..."
          system "android update test-project -m #{root} -p #{root}/test"
          raise "android update test-project failed with return code #{$?}" unless $? == 0
        end

        Dir.chdir File.join(root, 'test') do
          test_manifest = REXML::Document.new(File.read('AndroidManifest.xml')).root
          test_manifest.elements['application'].attributes['android:icon'] = '@drawable/icon'
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

          File.open("AndroidManifest.xml", 'w'){|f| test_manifest.document.write(f, 4)}
          instrumentation_property = "test.runner=org.ruboto.test.InstrumentationTestRunner\n"

          # FIXME(uwe): Cleanup when we stop supporting Android SDK <= 13
          prop_file = %w{ant.properties build.properties}.find{|f| File.exists?(f)}
          prop_lines = File.readlines(prop_file)
          File.open(prop_file, 'a'){|f| f << instrumentation_property} unless prop_lines.include?(instrumentation_property)
          # FIXME end

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
                <matches string="${tests.output}" pattern="OK \\(\\d+ tests\\)" multiline="true"/>
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
          # TODO(uwe): Old patches without delimiter.  Remove when we stop supporting upgrading from ruboto-core 0.2.0 and older.
          ant_script.gsub!(/\s*<macrodef name="run-tests-helper">.*?<\/macrodef>\s*/m, '')
          ant_script.gsub!(/\s*<target name="run-tests-quick".*?<\/target>\s*/m, '')
          # TODO end
          ant_script.gsub!(/\s*<!-- BEGIN added by ruboto(?:-core)? -->.*?<!-- END added by ruboto(?:-core)? -->\s*/m, '')
          raise "Bad ANT script" unless ant_script.gsub!(ant_setup_line, "#{run_tests_override}\n\n\\1")
          File.open('build.xml', 'w'){|f| f << ant_script}

          # FIXME(uwe): Remove when we stop supporting update from Ruboto <= 0.5.2
          if File.directory? 'assets/scripts'
            log_action 'Moving test scripts to the "src" directory.' do
              FileUtils.mv Dir['assets/scripts/*'], 'src'
              FileUtils.rm_rf 'assets/scripts'
            end
          end
          # FIXME end
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
        log_action("Removing #{jruby_core}") {File.delete *Dir.glob("libs/jruby-core-*.jar")} if jruby_core
        log_action("Removing #{jruby_stdlib}") {File.delete *Dir.glob("libs/jruby-stdlib-*.jar")} if jruby_stdlib
        log_action("Copying #{JRubyJars::core_jar_path} to libs") {copier.copy_from_absolute_path JRubyJars::core_jar_path, "libs"}
        log_action("Copying #{JRubyJars::stdlib_jar_path} to libs") {copier.copy_from_absolute_path JRubyJars::stdlib_jar_path, "libs"}

        reconfigure_jruby_libs(new_jruby_version)

        puts "JRuby version is now: #{new_jruby_version}"
        true
      end

      def update_assets
        puts "\nCopying files:"
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'

        %w{.gitignore Rakefile assets libs res/layout test}.each do |f|
          log_action(f) {copier.copy f}
        end

        # FIXME(uwe): Remove when we stop supporting Android SDK 17
        %w{anttasks.jar}.each do |f|
          log_action(f) {copier.copy f}
        end
        # FIXME end

        # FIXME(uwe):  Remove when we stop supporting upgrades from ruboto-core 0.3.3 and older
        old_scripts_dir = 'assets/scripts'
        if File.exists? old_scripts_dir
          FileUtils.mv Dir["#{old_scripts_dir}/*"], SCRIPTS_DIR
          FileUtils.rm_rf old_scripts_dir
        end
        # FIXME end

      end

      def update_icons(force = nil)
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.', force
        log_action('icons') do
          copier.copy 'res/drawable*/icon.png'
          copier.copy 'res/drawable/get_ruboto_core.png'
          copier.copy 'res/drawable*/icon.png', 'test'
        end
      end

      def update_classes(force = nil)
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'
        log_action("Ruboto java classes"){copier.copy "src/org/ruboto/*.java"}
        log_action("Ruboto java test classes"){copier.copy "src/org/ruboto/test/*.java", "test"}
        Dir["src/#{verify_package.gsub('.', '/')}/*.java"].each do |f|
          if File.read(f) =~ /public class (.*?) extends org.ruboto.Ruboto(Activity|BroadcastReceiver|Service) \{/
            subclass_name, class_name = $1, $2
            puts "Regenerating #{subclass_name}"
            generate_inheriting_file(class_name, subclass_name, verify_package)

            # FIXME(uwe): Remove when we stop supporting upgrading from ruboto-core 0.3.3 and older
            if class_name == 'BroadcastReceiver'
              script_file = File.expand_path("#{SCRIPTS_DIR}/#{underscore(subclass_name)}.rb")
              script_content = File.read(script_file)
              if script_content !~ /\$broadcast_receiver.handle_receive do \|context, intent\|/
                puts "Putting receiver script in a block in #{script_file}"
                script_content.gsub! '$broadcast_context', 'context'
                File.open(script_file, 'w') do |of|
                  of.puts '$broadcast_receiver.handle_receive do |context, intent|'
                  of << script_content
                  of.puts 'end'
                end
              end
            end
            # FIXME end

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
          app_element.attributes['android:icon'] ||= '@drawable/icon'

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
        generate_core_classes(:class => "all", :method_base => "on", :method_include => "", :method_exclude => "", :force => force, :implements => "")
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
          Dir.glob(Ruboto::GEM_ROOT + "/assets/#{SCRIPTS_DIR}/ruboto/*.rb").each do |i|
            from = File.expand_path(i)
            to = File.expand_path("./#{SCRIPTS_DIR}/ruboto/#{File.basename(i)}")
            FileUtils.mkdir_p File.dirname(to)
            FileUtils.cp from, to
          end
          Dir.glob(Ruboto::GEM_ROOT + "/assets/#{SCRIPTS_DIR}/ruboto/util/*.rb").each do |i|
            from = File.expand_path(i)
            to = File.expand_path("./#{SCRIPTS_DIR}/ruboto/util/#{File.basename(i)}")
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
                    'com/headius',
                    'com/kenai/constantine', 'com/kenai/jffi', 'com/martiansoftware', 'ext', 'java',
                    'jline', 'jni',
                    'jnr/constants/platform/darwin', 'jnr/constants/platform/fake', 'jnr/constants/platform/freebsd',
                    'jnr/constants/platform/openbsd', 'jnr/constants/platform/sunos', 'jnr/constants/platform/windows',
                    'jnr/ffi/annotations', 'jnr/ffi/byref', 'jnr/ffi/provider', 'jnr/ffi/util',
                    'jnr/ffi/posix/util',
                    'org/apache',
                    'org/bouncycastle', # TODO(uwe): Issue #154 Add back when we add jruby-openssl.  The bouncycastle included in Android is cripled.
                    'org/jruby/ant',
                    # 'org/jruby/compiler',      # Needed for initialization, but shoud not be necessary
                    # 'org/jruby/compiler/impl', # Needed for initialization, but shoud not be necessary
                    'org/jruby/compiler/util',
                    'org/jruby/demo', 'org/jruby/embed/bsf',
                    'org/jruby/embed/jsr223', 'org/jruby/embed/osgi', 'org/jruby/ext/ffi', 'org/jruby/javasupport/bsf',
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
                # TODO end

                # TODO(uwe): Remove when we stop supporting jruby-jars-1.6.2
                if jruby_core_version == '1.6.2'
                  print 'Retaining FFI for JRuby 1.6.2...'
                  excluded_core_packages.delete('org/jruby/ext/ffi')
                end
                # TODO end
              end

              excluded_core_packages.each do |i|
                FileUtils.remove_dir(i, true) rescue puts "Failed to remove package: #{i} (#{$!})"
              end

              # Uncomment this section to get a jar for each top level package in the core
              #Dir['**/*'].select{|f| !File.directory?(f)}.map{|f| File.dirname(f)}.uniq.sort.reverse.each do |dir|
              #  `jar -cf ../jruby-core-#{dir.gsub('/', '.')}-#{jruby_core_version}.jar #{dir}`
              #  FileUtils.rm_rf dir
              #end

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
                if Gem::Requirement.new('< 1.7.0.dev') =~ jruby_version
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
