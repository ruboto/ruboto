module Ruboto
  module Util
    module Setup
      # Todo: Find a way to look this up
      ANDROID_SDK_VERSION = "21.1"

      ANDROID_DEFAULT_API_LEVEL = 'android-10'

      #########################################
      #
      # Core Set up Method
      #

      def setup_ruboto
        check =  check_all

        if not check and RbConfig::CONFIG['host_os'] == /^windows(.*)/
          puts "\nWe can't directly install Android on Windows."
          puts 'If you would like to contribute to the setup for Windows,'
          puts 'please file an issue at https://github.com/ruboto/ruboto/issues'
          puts
          return
       end

       install_all if not check
       config_path
      end

      #########################################
      #
      # Utility Methods
      #

      def android_package_os_id
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/ then "macosx"
        when /^linux(.*)/ then "linux"
        when /^windows(.*)/ then "windows"
        else
          ## Error
          nil
        end
      end

      def android_package_directory
        "android-sdk-#{android_package_os_id}"
      end

      def api_level
        begin
          return $1 if File.read('project.properties') =~ /target=(.*)/
        rescue
        end

        return ANDROID_DEFAULT_API_LEVEL
      end

      def path_setup_file
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/ then ".profile"
        when /^linux(.*)/ then ".bashrc"
        when /^windows(.*)/ then "windows"
          ## Error
        else
          ## Error
          nil
        end
      end

      #
      # OS independent "which"
      # From: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      #
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
          }
        end
        return nil
      end

      #########################################
      #
      # Check Methods
      #

      def check_all
        @missing_paths = []

        @java_loc = check_for("java", "Java")
        @javac_loc = check_for("javac", "Java Compiler")
        @ant_loc = check_for("ant", "Apache ANT")
        @android_loc = check_for("android", "Android Package Installer", 
                                  File.join(File.expand_path("~"), android_package_directory, 'tools', 'android'))
        @emulator_loc = check_for("emulator", "Android Emulator")
        @adb_loc = check_for("adb", "Android SDK Command adb",
                              File.join(File.expand_path("~"), android_package_directory, 'platform-tools', 'adb'))
        @dx_loc = check_for("dx", "Android SDK Command dx")
        check_for_android_platform

        puts
        if @java_loc && @javac_loc && @adb_loc && @dx_loc && @emulator_loc && @platform_sdk_loc
          puts "    *** Ruboto setup is OK! ***\n"
          return true
        else
          puts "    !!! Ruboto setup is NOT OK !!!\n"
          return false
        end
      end

      def check_for(cmd, pretty_name=nil, alt_dir=nil)
        rv = which(cmd)
        rv = nil if rv.nil? or rv.empty?

        if rv.nil? and alt_dir and File.exists?(alt_dir)
          rv = alt_dir
          ENV['PATH'] = "#{File.dirname(rv)}:#{ENV['PATH']}"
          @missing_paths << "#{File.dirname(rv)}"
        end

        puts "#{pretty_name || cmd}: " + (rv ?  "Found at #{rv}" : "Not found")
        rv
      end

      def check_for_android_platform
        begin
          @platform_sdk_loc = File.expand_path "#{@dx_loc}/../../platforms/#{api_level}"
          if File.exists? @platform_sdk_loc
            puts "Android platform SDK: Found at #{@platform_sdk_loc}"
          else
            puts "Android platform SDK: Not found"
            @platform_sdk_loc = nil
          end
        rescue
          @platform_sdk_loc = nil
        end
      end

      #########################################
      #
      # Install Methods
      #

      def install_all
        install_android
        install_adb
        install_platform
      end

      def install_android
        unless @android_loc
          puts 'Android package installer not found.'
          print 'Would you like to download and install it? (Y/n): '
          a = STDIN.gets.chomp.upcase
          if a == 'Y' || a.empty?
            Dir.chdir File.expand_path('~/') do
              case RbConfig::CONFIG['host_os']
              when /^darwin(.*)/ 
                asdk_file_name = "android-sdk_r#{ANDROID_SDK_VERSION}-#{android_package_os_id}.zip"
                system "wget http://dl.google.com/android/#{asdk_file_name}"
                system "unzip #{asdk_file_name}"
                system "rm #{asdk_file_name}"
              when /^linux(.*)/
                asdk_file_name = "android-sdk_r#{ANDROID_SDK_VERSION}-#{android_package_os_id}.tgz"
                system "wget http://dl.google.com/android/#{asdk_file_name}"
                system "tar -xzf #{asdk_file_name}"
                system "rm #{asdk_file_name}"
              when /^windows(.*)/
                # Todo: Need platform independent download
                ## Error
                asdk_file_name = "installer_r#{ANDROID_SDK_VERSION}-#{android_package_os_id}.exe"
                return
              end
            end
            @android_loc = File.join(File.expand_path("~"), android_package_directory, 'tools', 'android')
            ENV['PATH'] = "#{File.dirname(@android_loc)}:#{ENV['PATH']}"
            @missing_paths << "#{File.dirname(@android_loc)}"
          end
        end
      end

      def install_adb
        if @android_loc and not @adb_loc
          puts 'Android command adb not found.'
          print 'Would you like to download and install it? (Y/n): '
          a = STDIN.gets.chomp.upcase
          if a == 'Y' || a.empty?
            system 'android update sdk --no-ui --filter tool,platform-tool'
            @adb_loc = File.join(File.expand_path("~"), android_package_directory, 'platform-tools', 'adb')
            ENV['PATH'] = "#{File.dirname(@adb_loc)}:#{ENV['PATH']}"
            @missing_paths << "#{File.dirname(@adb_loc)}"
          end
        end
      end

      def install_platform
        if @android_loc and not @platform_sdk_loc
          puts "Android platform SDK for #{api_level} not found."
          print 'Would you like to download and install it? (Y/n): '
          a = STDIN.gets.chomp.upcase
          if a == 'Y' || a.empty?
            system "android update sdk --no-ui --filter #{api_level},sysimg-#{api_level.slice(/\d+$/)} --all"
            @platform_sdk_loc = File.expand_path "#{@dx_loc}/../../platforms/#{api_level}"
          end
        end
      end

      #########################################
      #
      # Path Config Method
      #

      def config_path
        unless @missing_paths.empty?
          puts "\nYou are missing some paths.  Execute these lines to add them:\n\n"
          @missing_paths.each do |path|
            puts %Q{    export PATH="#{path}:$PATH"}
          end
          print "\nWould you like to append these lines to your configuration script? (Y/n): "
          a = STDIN.gets.chomp.upcase
          if a == 'Y' || a.empty?
            print "What script do you use to configure your PATH? (#{path_setup_file}): "
            a = STDIN.gets.chomp.downcase

            File.open(File.expand_path("~/#{a.empty? ? path_setup_file : a}"), 'a') do |f|
              f.puts "\n# BEGIN Ruboto PATH setup"
              @missing_paths.each{|path| f.puts %Q{export PATH="#{path}:$PATH"}}
              f.puts '# END Ruboto PATH setup'
              f.puts
            end
            puts "Path updated. Please close your command window and reopen."
          end
        end
      end
    end
  end
end
