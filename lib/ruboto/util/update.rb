module Ruboto
  module Util
    module Update
      ###########################################################################
      #
      # Updating components
      #

      def update_jruby(force=nil)
        jruby_core = Dir.glob("libs/jruby-core-*.jar")[0]
        jruby_stdlib = Dir.glob("libs/jruby-stdlib-*.jar")[0]
        new_jruby_version = JRubyJars::core_jar_path.split('/')[-1][11..-5]

        unless force
          abort "cannot find existing jruby jars in libs. Make sure you're in the root directory of your app" if
          (not jruby_core or not jruby_stdlib)

          current_jruby_version = jruby_core ? jruby_core[16..-5] : "None"
          abort "both jruby versions are #{new_jruby_version}. Nothing to update. Make sure you 'gem update jruby-jars' if there is a new version" if
          current_jruby_version == new_jruby_version

          puts "Current jruby version: #{current_jruby_version}"
          puts "New jruby version: #{new_jruby_version}"
        end

        copier = AssetCopier.new Ruboto::ASSETS, File.expand_path(".")
        log_action("Removing #{jruby_core}") {File.delete jruby_core} if jruby_core
        log_action("Removing #{jruby_stdlib}") {File.delete jruby_stdlib} if jruby_stdlib
        log_action("Copying #{JRubyJars::core_jar_path} to libs") {copier.copy_from_absolute_path JRubyJars::core_jar_path, "libs"}
        log_action("Copying #{JRubyJars::stdlib_jar_path} to libs") {copier.copy_from_absolute_path JRubyJars::stdlib_jar_path, "libs"}

        reconfigure_jruby_libs

        puts "JRuby version is now: #{new_jruby_version}"
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

          abort "The ruboto.rb version has not changed. Use --force to force update." if
          from_text[/\$RUBOTO_VERSION = (\d+)/, 1] == to_text[/\$RUBOTO_VERSION = (\d+)/, 1]
        end

        log_action("Copying ruboto.rb and setting the package name") do
          File.open(to, 'w') {|f| f << from_text.gsub("THE_PACKAGE", verify_package).gsub("ACTIVITY_NAME", verify_activity)}
        end
      end

      #
      # reconfigure_jruby_libs:
      #   - removes unneeded code from jruby-core
      #   - moves ruby stdlib to the root of the ruby-stdlib jar
      #

      def reconfigure_jruby_libs
        jruby_core = JRubyJars::core_jar_path.split('/')[-1]
        log_action("Removing unneeded classes from #{jruby_core}") do
          Dir.mkdir "libs/tmp"
          Dir.chdir "libs/tmp"
          FileUtils.move "../#{jruby_core}", "."
          `jar -xf #{jruby_core}`
          File.delete jruby_core
          ['cext', 'jni', 'org/jruby/ant', 'org/jruby/compiler/ir', 'org/jruby/demo', 'org/jruby/embed/bsf',
            'org/jruby/embed/jsr223', 'org/jruby/ext/ffi','org/jruby/javasupport/bsf'
            ].each {|i| FileUtils.remove_dir i, true}
            `jar -cf ../#{jruby_core} .`
            Dir.chdir "../.."
            FileUtils.remove_dir "libs/tmp", true
          end

          jruby_stdlib = JRubyJars::stdlib_jar_path.split('/')[-1]
          log_action("Reformatting #{jruby_stdlib}") do
            Dir.mkdir "libs/tmp"
            Dir.chdir "libs/tmp"
            FileUtils.move "../#{jruby_stdlib}", "."
            `jar -xf #{jruby_stdlib}`
            File.delete jruby_stdlib
            FileUtils.move "META-INF/jruby.home/lib/ruby/1.8", ".."
            Dir["META-INF/jruby.home/lib/ruby/site_ruby/1.8/*"].each do |f|
              next if File.basename(f) =~ /^..?$/
              FileUtils.move f, "../1.8/" + File.basename(f)
            end
            Dir.chdir "../1.8"
            FileUtils.remove_dir "../tmp", true
            `jar -cf ../#{jruby_stdlib} .`
            Dir.chdir "../.."
            FileUtils.remove_dir "libs/1.8", true
          end
        end
      end
    end
  end