require 'ruboto/sdk_versions'

module Ruboto
  module Util
    module Setup
      include Ruboto::SdkVersions
      # Todo: Find a way to look this up
      ANDROID_SDK_VERSION = '21.1'

      #########################################
      #
      # Core Set up Method
      #

      def setup_ruboto
        check = check_all

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
        when /^darwin(.*)/ then
          'macosx'
        when /^linux(.*)/ then
          'linux'
        when /^mswin32|windows(.*)/ then
          'windows'
        else
          ## Error
          nil
        end
      end

      def android_package_directory
        if RbConfig::CONFIG['host_os'] =~ /^mswin32|windows(.*)/
          'AppData/Local/Android/android-sdk'
        else
          "android-sdk-#{android_package_os_id}"
        end
      end

      def api_level
        begin
          return $1 if File.read('project.properties') =~ /target=(.*)/
        rescue
          # ignored
        end
        DEFAULT_TARGET_SDK
      end

      def path_setup_file
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/ then
          '.profile'
        when /^linux(.*)/ then
          '.bashrc'
        when /^mswin32|windows(.*)/ then
          'windows'
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
        nil
      end

      #########################################
      #
      # Check Methods
      #

      def check_all
        @missing_paths = []

        @java_loc = check_for('java', 'Java')
        @javac_loc = check_for('javac', 'Java Compiler')
        @ant_loc = check_for('ant', 'Apache ANT')
        @android_loc = check_for('android', 'Android Package Installer',
                                 File.join(File.expand_path('~'), android_package_directory, 'tools', 'android'))
        @emulator_loc = check_for('emulator', 'Android Emulator')
        @adb_loc = check_for('adb', 'Android SDK Command adb',
                             File.join(File.expand_path('~'), android_package_directory, 'platform-tools', 'adb'))
        @dx_loc = check_for('dx', 'Android SDK Command dx')
        check_for_android_platform

        puts
        if @java_loc && @javac_loc && @adb_loc && @dx_loc && @emulator_loc && @platform_sdk_loc
          puts "    *** Ruboto setup is OK! ***\n\n"
          true
        else
          puts "    !!! Ruboto setup is NOT OK !!!\n\n"
          false
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

        puts "#{pretty_name || cmd}: " + (rv ? "Found at #{rv}" : 'Not found')
        rv
      end

      def check_for_android_platform
        begin
          @platform_sdk_loc = File.expand_path "#{@dx_loc}/../../platforms/#{api_level}"
          if File.exists? @platform_sdk_loc
            puts "Android platform SDK: Found at #{@platform_sdk_loc}"
          else
            puts 'Android platform SDK: Not found'
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
        install_java
        install_android
        install_adb
        install_platform
      end

      def install_java
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/
        when /^linux(.*)/
        when /^mswin32|windows(.*)/
          # FIXME(uwe):  Detect and warn if we are not "elevated" with adminstrator rights.
          #set IS_ELEVATED=0
          #whoami /groups | findstr /b /c:"Mandatory Label\High Mandatory Level" | findstr /c:"Enabled group" > nul: && set IS_ELEVATED=1
          #if %IS_ELEVATED%==0 (
          #    echo You must run the command prompt as administrator to install.
          #    exit /b 1
          #)

          java_installer_file_name = 'jdk-7-windows-x64.exe'
          require 'net/http'
          require 'net/https'
          resp = nil
          @cookies = ['gpw_e24=http%3A%2F%2Fwww.oracle.com']
          puts 'Downloading...'
          Net::HTTP.start('download.oracle.com') do |http|
            resp, _ = http.get("/otn-pub/java/jdk/7/#{java_installer_file_name}", cookie_header)
            resp.body
          end
          resp = process_response(resp)
          open(java_installer_file_name, 'wb') { |file| file.write(resp.body) }
          puts "Installing #{java_installer_file_name}..."
          system java_installer_file_name
          raise "Unexpected exit code while installing Java: #{$?}" unless $? == 0
          FileUtils.rm_f java_installer_file_name
          return
        else
          raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
        end
      end

      def cookie_header
        return {} if @cookies.empty?
        {'Cookie' => @cookies.join(';')}
      end
      private :cookie_header

      def store_cookie(response)
        return unless response['set-cookie']
        header = response['set-cookie']
        header.gsub! /expires=.{3},/, ''
        header.split(',').each do |cookie|
          cookie_value = cookie.strip.slice(/^.*?;/).chomp(';')
          if cookie_value =~ /^(.*?)=(.*)$/
            name = $1
            @cookies.delete_if { |c| c =~ /^#{name}=/ }
          end
          @cookies << cookie_value unless cookie_value =~ /^.*?=$/
        end
        @cookies.uniq!
      end
      private :store_cookie

      def process_response(response)
        store_cookie(response)
        if response.code == '302'
          redirect_url = response['location']
          puts "Following redirect to #{redirect_url}"
          url = URI.parse(redirect_url)
          if redirect_url =~ /^http:\/\//
            Net::HTTP.start(url.host, url.port) do |http|
              response = http.get(redirect_url, cookie_header)
              response.body
            end
          else
            http = Net::HTTP.new(url.host, url.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            response = http.get(redirect_url, cookie_header)
            response.body
          end
          return process_response(response)
        elsif response.code != '200'
          raise "Got response code #{response.code}"
        end
        response
      end
      private :process_response

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
              when /^mswin32|windows(.*)/
                # FIXME(uwe):  Detect and warn if we are not "elevated" with adminstrator rights.
                #set IS_ELEVATED=0
                #whoami /groups | findstr /b /c:"Mandatory Label\High Mandatory Level" | findstr /c:"Enabled group" > nul: && set IS_ELEVATED=1
                #if %IS_ELEVATED%==0 (
                #    echo You must run the command prompt as administrator to install.
                #    exit /b 1
                #)

                asdk_file_name = "installer_r#{ANDROID_SDK_VERSION}-#{android_package_os_id}.exe"
                require 'net/http'
                Net::HTTP.start('dl.google.com') do |http|
                  puts 'Downloading...'
                  resp = http.get("/android/#{asdk_file_name}")
                  open(asdk_file_name, 'wb') { |file| file.write(resp.body) }
                end
                puts "Installing #{asdk_file_name}..."
                system asdk_file_name
                raise "Unexpected exit code while installing the Android SDK: #{$?}" unless $? == 0
                FileUtils.rm_f asdk_file_name
                return
              else
                raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
              end
            end
            @android_loc = File.join(File.expand_path('~'), android_package_directory, 'tools', 'android')
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
            @adb_loc = File.join(File.expand_path('~'), android_package_directory, 'platform-tools', 'adb')
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
          if RbConfig::CONFIG['host_os'] =~ /^mswin32|windows(.*)/
            puts "\nYou are missing some paths.  Execute these lines to add them:\n\n"
            @missing_paths.each do |path|
              puts %Q{    set PATH="#{path.gsub '/', '\\'};%PATH%"}
            end
            system %Q{setx PATH "%PATH%;#{@missing_paths.map{|path| path.gsub '/', '\\'}.join(';')}"}
          else
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
                @missing_paths.each { |path| f.puts %Q{export PATH="#{path}:$PATH"} }
                f.puts '# END Ruboto PATH setup'
                f.puts
              end
              puts 'Path updated. Please close your command window and reopen.'
            end
          end
        end
      end
    end
  end
end
