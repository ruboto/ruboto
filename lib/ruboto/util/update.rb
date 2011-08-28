module Ruboto
  module Util
    module Update
      include Build
      ###########################################################################
      #
      # Updating components
      #
      def update_test(force = nil)
        root = Dir.getwd
        if force || !File.exists?("#{root}/test")
          name = verify_strings.root.elements['string'].text.gsub(' ', '')
          puts "\nGenerating Android test project #{name} in #{root}..."
          system "android create test-project -m #{root} -n #{name}Test -p #{root}/test"
          FileUtils.rm_rf File.join(root, 'test', 'src', verify_package.split('.'))
          puts "Done"
        else
          # TODO(uwe): Run "android update test"
          puts "Test project already exists.  Use --force to overwrite."
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
          prop_lines = File.readlines('build.properties')
          File.open('build.properties', 'a'){|f| f << instrumentation_property} unless prop_lines.include?(instrumentation_property)
          ant_setup_line = /^(\s*<setup\s*\/>)/
          run_tests_override = <<-EOF
<!-- BEGIN added by ruboto-core -->
    <macrodef name="run-tests-helper">
      <attribute name="emma.enabled" default="false"/>
      <element name="extra-instrument-args" optional="yes"/>
      <sequential>
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
<!-- END added by ruboto-core -->

EOF
          ant_script = File.read('build.xml')
          # TODO(uwe): Old patches without delimiter.  Remove when we stop supporting upgrading from ruboto-core 0.2.0 and older.
          ant_script.gsub!(/\s*<macrodef name="run-tests-helper">.*?<\/macrodef>\s*/m, '')
          ant_script.gsub!(/\s*<target name="run-tests-quick".*?<\/target>\s*/m, '')
          # TODO end
          ant_script.gsub!(/\s*<!-- BEGIN added by ruboto-core -->.*?<!-- END added by ruboto-core -->\s*/m, '')
          ant_script.gsub!(ant_setup_line, "\\1\n\n#{run_tests_override}")
          File.open('build.xml', 'w'){|f| f << ant_script}
        end
      end

      def update_jruby(force=nil, with_psych=nil)
        jruby_core = Dir.glob("libs/jruby-core-*.jar")[0]
        jruby_stdlib = Dir.glob("libs/jruby-stdlib-*.jar")[0]
        new_jruby_version = JRubyJars::VERSION

        unless force
          if !jruby_core || !jruby_stdlib
            puts "Cannot find existing jruby jars in libs. Make sure you're in the root directory of your app."
            return false
          end

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

        reconfigure_jruby_libs(new_jruby_version, with_psych)

        puts "JRuby version is now: #{new_jruby_version}"
        true
      end

      def update_assets
        puts "\nCopying files:"
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'

        %w{.gitignore Rakefile assets res/layout test}.each do |f|
          log_action(f) {copier.copy f}
        end
      end

      def update_icons(force = nil)
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.', force
        log_action('icons') do
          copier.copy 'res/drawable*/icon.png'
          copier.copy 'res/drawable*/icon.png', 'test'
        end
      end

      def update_classes(force = nil)
        copier = Ruboto::Util::AssetCopier.new Ruboto::ASSETS, '.'
        log_action("Ruboto java classes"){copier.copy "src/org/ruboto/*.java"}
        log_action("Ruboto java test classes"){copier.copy "src/org/ruboto/test/*.java", "test"}
        Dir["src/#{verify_package.gsub('.', '/')}/*.java"].each do |f|
          if File.read(f) =~ /public class (.*?) extends org.ruboto.Ruboto(Activity|BroadcastReceiver|Service) \{/
            puts "Regenerating #$1"
            generate_inheriting_file($2, $1, verify_package)
          end
        end
      end

      def update_manifest(min_sdk, target, force = false)
        log_action("\nAdding activities (RubotoActivity and RubotoDialog) and SDK versions to the manifest") do
          if sdk_element = verify_manifest.elements['uses-sdk']
            min_sdk ||= sdk_element.attributes["android:minSdkVersion"]
            target ||= sdk_element.attributes["android:targetSdkVersion"]
          end
          if min_sdk.to_i >= 11
            verify_manifest.elements['application'].attributes['android:hardwareAccelerated'] ||= 'true'
            verify_manifest.elements['application'].attributes['android:largeHeap'] ||= 'true'
          end
          app_element = verify_manifest.elements['application']
          if app_element.elements["activity[@android:name='org.ruboto.RubotoActivity']"]
            puts 'found activity tag'
          else
            app_element.add_element 'activity', {"android:name" => "org.ruboto.RubotoActivity", 'android:exported' => 'false'}
          end
          if app_element.elements["activity[@android:name='org.ruboto.RubotoDialog']"]
            puts 'found dialog tag'
          else
            app_element.add_element 'activity', {"android:name" => "org.ruboto.RubotoDialog", 'android:exported' => 'false', "android:theme" => "@android:style/Theme.Dialog"}
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
        verify_manifest

        from = File.expand_path(Ruboto::GEM_ROOT + "/assets/assets/scripts/ruboto.rb")
        to = File.expand_path("./assets/scripts/ruboto.rb")

        from_text = File.read(from)
        to_text = File.read(to) if File.exists?(to)

        unless force
          puts "New version: #{from_text[/\$RUBOTO_VERSION = (\d+)/, 1]}"
          puts "Old version: #{to_text ? to_text[/\$RUBOTO_VERSION = (\d+)/, 1] : 'none'}"

          if from_text[/\$RUBOTO_VERSION = (\d+)/, 1] == to_text[/\$RUBOTO_VERSION = (\d+)/, 1]
            puts "The ruboto.rb version has not changed. Use --force to force update."
            return false
          end
        end

        log_action("Copying ruboto.rb") do
          File.open(to, 'w') {|f| f << from_text}
        end
        true
      end

      def reconfigure_jruby_libs(jruby_core_version, with_psych=nil)
        reconfigure_jruby_core(jruby_core_version)
        reconfigure_jruby_stdlib(with_psych)
      end

      # - Removes unneeded code from jruby-core
      # - Split into smaller jars that can be used separately
      def reconfigure_jruby_core(jruby_core_version)
        jruby_core = JRubyJars::core_jar_path.split('/')[-1]
        Dir.chdir 'libs' do
          log_action("Removing unneeded classes from #{jruby_core}") do
            Dir.mkdir "tmp"
            Dir.chdir "tmp" do
              FileUtils.move "../#{jruby_core}", "."
              `jar -xf #{jruby_core}`
              File.delete jruby_core
              excluded_core_packages = [
                'META-INF', 'cext', 'com/kenai/constantine', 'com/kenai/jffi', 'com/martiansoftware', 'ext', 'java',
                'jline', 'jni',
                'jnr/constants/platform/darwin', 'jnr/constants/platform/fake', 'jnr/constants/platform/freebsd',
                'jnr/constants/platform/openbsd', 'jnr/constants/platform/sunos', 'jnr/constants/platform/windows',
                'org/apache', 'org/jruby/ant', 'org/jruby/compiler/ir', 'org/jruby/demo', 'org/jruby/embed/bsf',
                'org/jruby/embed/jsr223', 'org/jruby/embed/osgi', 'org/jruby/ext/ffi', 'org/jruby/javasupport/bsf',
              ]

              # TODO(uwe): Remove when we stop supporting jruby-jars < 1.7.0
              if jruby_core_version < '1.7.0'
                print 'Retaining com.kenai.constantine and removing jnr for JRuby < 1.7.0...'
                excluded_core_packages << 'jnr'
                excluded_core_packages.delete 'com/kenai/constantine'
              end
              # TODO end

              # TODO(uwe): Remove when we stop supporting jruby-jars-1.6.2
              if jruby_core_version == '1.6.2'
                print 'Retaining FFI for JRuby 1.6.2...'
                excluded_core_packages.delete('org/jruby/ext/ffi')
              end
              # TODO end

              excluded_core_packages.each {|i| FileUtils.remove_dir i, true}

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
      def reconfigure_jruby_stdlib(with_psych=nil)
        excluded_stdlibs = %w{} + (verify_ruboto_config[:excluded_stdlibs] || [])
        Dir.chdir 'libs' do
          jruby_stdlib = JRubyJars::stdlib_jar_path.split('/')[-1]
          stdlib_1_8_files = nil
          log_action("Reformatting #{jruby_stdlib}") do
            Dir.mkdir "tmp"
            Dir.chdir "tmp" do
              FileUtils.move "../#{jruby_stdlib}", "."
              `jar -xf #{jruby_stdlib}`
              File.delete jruby_stdlib

              FileUtils.move "META-INF/jruby.home/lib/ruby/1.8", ".."
              Dir["META-INF/jruby.home/lib/ruby/site_ruby/1.8/*"].each do |f|
                next if File.basename(f) =~ /^..?$/
                FileUtils.move f, "../1.8/" + File.basename(f)
              end
              Dir["META-INF/jruby.home/lib/ruby/site_ruby/shared/*"].each do |f|
                next if File.basename(f) =~ /^..?$/
                FileUtils.move f, "../1.8/" + File.basename(f)
              end
            end
            Dir.chdir "1.8" do
              if excluded_stdlibs.any?
                excluded_stdlibs.each { |d| FileUtils.rm_rf d }
                print "excluded #{excluded_stdlibs.join(' ')}..."
              end

              stdlib_1_8_files = Dir['**/*']

              # Uncomment this part to split the stdlib into one jar per directory
              # Dir['*'].select{|f| File.directory? f}.each do |d|
              #    `jar -cf ../jruby-stdlib-#{d}-#{JRubyJars::VERSION}.jar #{d}`
              #    FileUtils.rm_rf d
              # end

              `jar -cf ../#{jruby_stdlib} .`
            end
          end

          psych_jar = "psych.jar"
          psych_already_present = File.exists? psych_jar
          FileUtils.rm_f psych_jar

          if with_psych || with_psych.nil? && psych_already_present
            log_action("Adding psych #{File.basename psych_jar}") do
              psych_dir = 'psych'
              FileUtils.move "tmp/META-INF/jruby.home/lib/ruby/1.9", psych_dir
              Dir.chdir psych_dir do
                if excluded_stdlibs.any?
                  excluded_stdlibs.each { |d| FileUtils.rm_rf d }
                  print "excluded #{excluded_stdlibs.join(' ')}..."
                end
                psych_files = Dir["**/*"]
                puts if psych_files.any?
                psych_files.each do |f|
                  next if File.basename(f) =~ /^..?$/
                  if stdlib_1_8_files.include? f
                    puts "Removing duplicate #{f}"
                    FileUtils.rm_f f
                  end
                end
                `jar -cf ../#{psych_jar} .`
              end
              FileUtils.remove_dir psych_dir, true
            end
          end

          FileUtils.remove_dir "tmp", true
          FileUtils.remove_dir "1.8", true
        end
      end

      def update_build_xml
        ant_setup_line = /^(\s*<setup\s*\/>)/
        patch = <<-EOF
    <!-- BEGIN added by ruboto-core -->
    <target name="ruboto-install-debug" description="Installs the already built debug package">
        <install-helper />
    </target>
    <!-- END added by ruboto-core -->

    EOF
        ant_script = File.read('build.xml')
        ant_script.gsub!(/\s*<!-- BEGIN added by ruboto-core -->.*?<!-- END added by ruboto-core -->\s*\n*/m, '')
        ant_script.gsub!(ant_setup_line, "\\1\n\n#{patch}")
        File.open('build.xml', 'w'){|f| f << ant_script}
      end

    end
  end
end
