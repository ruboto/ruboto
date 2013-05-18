require 'pty'
require 'ruboto/sdk_versions'

module Ruboto
  module Util
    module Setup
      # Todo: Find a way to look this up
      ANDROID_SDK_VERSION = '22'
      BUILD_TOOLS_VERSION = '17.0.0'
      # odoT

      #########################################
      #
      # Core Set up Method
      #

      def setup_ruboto(accept_all)
        install_all(accept_all) unless check_all
        config_path(accept_all)
      end

      #
      # OS independent "which"
      # From: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      #
      def self.which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
          end
        end
        nil
      end

      def which(cmd)
        Setup.which(cmd)
      end

      private

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
        SdkVersions::DEFAULT_TARGET_SDK
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

      #########################################
      #
      # Check Methods
      #

      def check_all
        @existing_paths = []
        @missing_paths = []

        @java_loc = check_for('java', 'Java runtime')
        @javac_loc = check_for('javac', 'Java Compiler')
        @ant_loc = check_for('ant', 'Apache ANT')
        check_for_android_sdk
        check_for_emulator
        check_for_platform_tools
        check_for_build_tools
        check_for_android_platform

        puts
        if @java_loc && @javac_loc && @ant_loc && @android_loc && @emulator_loc && @adb_loc && @dx_loc && @platform_sdk_loc
          puts "    *** Ruboto setup is OK! ***\n\n"
          true
        else
          puts "    !!! Ruboto setup is NOT OK !!!\n\n"
          false
        end
      end

      def check_for_emulator
        @emulator_loc = check_for('emulator', 'Android Emulator',
                                  File.join(File.expand_path('~'), android_package_directory, 'tools', 'emulator'))
      end

      def check_for_platform_tools
        @adb_loc = check_for('adb', 'Android SDK Command adb',
                             File.join(File.expand_path('~'), android_package_directory, 'platform-tools', 'adb'))
      end

      def check_for_build_tools
        @dx_loc = check_for('dx', 'Android SDK Command dx',
                            Dir[File.join(File.expand_path('~'), android_package_directory, 'build-tools', '*', 'dx')][-1])
      end

      def check_for_android_sdk
        @android_loc = check_for('android', 'Android Package Installer',
                                 File.join(File.expand_path('~'), android_package_directory, 'tools', 'android'))
      end

      def check_for(cmd, pretty_name=nil, alt_dir=nil)
        rv = which(cmd)
        rv = nil if rv.nil? or rv.empty?

        if rv
          @existing_paths << File.dirname(rv)
        elsif alt_dir and File.exists?(alt_dir)
          rv = alt_dir
          ENV['PATH'] = "#{File.dirname(rv)}:#{ENV['PATH']}"
          @missing_paths << "#{File.dirname(rv)}"
        end

        puts "#{'%-25s' % (pretty_name || cmd)}: " + (rv ? 'Found' : 'Not found')
        rv
      end

      def check_for_android_platform
        begin
          @platform_sdk_loc = File.expand_path "#{@android_loc}/../../platforms/#{api_level}"
          if File.exists? @platform_sdk_loc
            puts 'Android platform SDK     : Found'
          else
            puts 'Android platform SDK     : Not found'
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

      def install_all(accept_all)
        install_java(accept_all) unless @java_loc && @javac_loc
        install_ant(accept_all) unless @ant_loc
        install_android_sdk(accept_all) unless @android_loc
        install_android_tools(accept_all) unless @dx_loc && @adb_loc && @emulator_loc # build-tools, platform-tools and tools
        install_platform(accept_all) unless @platform_sdk_loc
      end

      def install_java(accept_all)
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

          puts 'Java JDK was not found.'
          unless accept_all
            print 'Would you like to download and install it? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            java_installer_file_name = 'jdk-7-windows-x64.exe'
            require 'net/http'
            require 'net/https'
            resp = nil
            @cookies = %w(gpw_e24=http%3A%2F%2Fwww.oracle.com)
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
          else
            puts
            puts 'You can download and install the Java JDK manually from'
            puts 'http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html'
            puts
          end
          unless check_for('javac')
            ENV['JAVA_HOME'] = 'c:\\Program Files\\Java\\jdk1.7.0'
            if Dir.exists?(ENV['JAVA_HOME'])
              @javac_loc = "#{ENV['JAVA_HOME'].gsub('\\', '/')}/bin/javac"
              puts "Setting the JAVA_HOME environment variable to #{ENV['JAVA_HOME']}"
              system %Q{setx JAVA_HOME "#{ENV['JAVA_HOME']}"}
              @missing_paths << "#{File.dirname(@javac_loc)}"
            end
          end
        else
          raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
        end
      end

      def install_ant(accept_all)
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

          puts 'Apache ANT was not found.'
          unless accept_all
            print 'Would you like to download and install it? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            Dir.chdir Dir.home do
              ant_package_file_name = 'apache-ant-1.9.0-bin.tar.gz'
              require 'net/http'
              require 'net/https'
              puts 'Downloading...'
              Net::HTTP.start('apache.vianett.no') do |http|
                resp, _ = http.get("/ant/binaries/#{ant_package_file_name}")
                open(ant_package_file_name, 'wb') { |file| file.write(resp.body) }
              end
              puts "Installing #{ant_package_file_name}..."
              require 'rubygems/package'
              require 'zlib'
              Gem::Package::TarReader.new(Zlib::GzipReader.open(ant_package_file_name)).each do |entry|
                puts entry.full_name
                if entry.directory?
                  FileUtils.mkdir_p entry.full_name
                elsif entry.file?
                  FileUtils.mkdir_p File.dirname(entry.full_name)
                  File.open(entry.full_name, 'wb') { |f| f << entry.read }
                end
              end
              FileUtils.rm_f ant_package_file_name
            end
          else
            puts
            puts 'You can download and install Apache ANT manually from'
            puts 'http://ant.apache.org/bindownload.cgi'
            puts
          end
          unless check_for('ant')
            ENV['ANT_HOME'] = File.expand_path(File.join('~', 'apache-ant-1.9.0')).gsub('/', '\\')
            if Dir.exists?(ENV['ANT_HOME'])
              @ant_loc = "#{ENV['ANT_HOME'].gsub('\\', '/')}/bin/ant"
              puts "Setting the ANT_HOME environment variable to #{ENV['ANT_HOME']}"
              system %Q{setx ANT_HOME "#{ENV['ANT_HOME']}"}
              @missing_paths << "#{File.dirname(@ant_loc)}"
            end
          end
        else
          raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
        end
      end

      def cookie_header
        return {} if @cookies.empty?
        {'Cookie' => @cookies.join(';')}
      end

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

      def install_android_sdk(accept_all)
        unless @android_loc
          puts 'Android package installer not found.'
          unless accept_all
            print 'Would you like to download and install it? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            Dir.chdir File.expand_path('~/') do
              case RbConfig::CONFIG['host_os']
              when /^darwin(.*)/
                asdk_file_name = "android-sdk_r#{ANDROID_SDK_VERSION}-#{android_package_os_id}.zip"
                system "wget http://dl.google.com/android/#{asdk_file_name}"
                system "unzip #{'-o ' if accept_all}#{asdk_file_name}"
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
          end
          check_for_android_sdk
          unless @android_loc
            ENV['ANDROID_HOME'] = @android_loc.gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
            puts "Setting the ANDROID_HOME environment variable to #{ENV['ANDROID_HOME']}"
            system %Q{setx ANDROID_HOME "#{ENV['ANDROID_HOME']}"}
            @missing_paths << "#{File.dirname(@android_loc)}"
          end
        end
      end

      def install_android_tools(accept_all)
        if @android_loc and (@dx_loc.nil? || @adb_loc.nil? || @emulator_loc.nil?)
          puts 'Android tools not found.'
          unless accept_all
            print 'Would you like to download and install it? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            update_cmd = "android --silent update sdk --no-ui --filter build-tools-#{BUILD_TOOLS_VERSION},platform-tool,tool --force"
            update_sdk(update_cmd, accept_all)
            check_for_build_tools
            check_for_platform_tools
            check_for_emulator
          end
        end
      end

      def install_platform(accept_all)
        if @android_loc and not @platform_sdk_loc
          puts "Android platform SDK for #{api_level} not found."
          unless accept_all
            print 'Would you like to download and install it? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            update_cmd = "android --silent update sdk --no-ui --filter #{api_level},sysimg-#{api_level.slice(/\d+$/)} --all"
            update_sdk(update_cmd, accept_all)
            check_for_android_platform
          end
        end
      end

      def update_sdk(update_cmd, accept_all)
        begin
          PTY.spawn(update_cmd) do |stdin, stdout, pid|
            begin
              output = ''
              question_pattern = /.*Do you accept the license '[a-z-]+-[0-9a-f]{8}' \[y\/n\]: /m
              stdin.each_char do |text|
                print text
                output << text

                #puts
                #puts output
                #puts((output =~ question_pattern).inspect)

                if accept_all && output =~ question_pattern
                  stdout.puts 'y'
                  output.sub! question_pattern, ''
                end
              end
            rescue Errno::EIO
              puts 'Errno:EIO error, but this probably just means that the process has finished giving output'
              sleep 1
            end
          end
        rescue PTY::ChildExited
          puts 'The child process exited!'
        end
      end

      #########################################
      #
      # Path Config Method
      #

      def config_path(accept_all)
        unless @missing_paths.empty?
          if RbConfig::CONFIG['host_os'] =~ /^mswin32|windows(.*)/
            puts "\nYou are missing some paths.  Execute these lines to add them:\n\n"
            @missing_paths.each do |path|
              puts %Q{    set PATH="#{path.gsub '/', '\\'};%PATH%"}
            end
            system %Q{setx PATH "%PATH%;#{@missing_paths.map { |path| path.gsub '/', '\\' }.join(';')}"}
          else
            puts "\nYou are missing some paths.  Execute these lines to add them:\n\n"
            @missing_paths.each do |path|
              puts %Q{    export PATH="#{path}:$PATH"}
            end
            puts
            unless accept_all
              print "\nWould you like to append these lines to your configuration script? (Y/n): "
              a = STDIN.gets.chomp.upcase
            end
            if accept_all || a == 'Y' || a.empty?
              unless accept_all
                print "What script do you use to configure your PATH? (#{path_setup_file}): "
                a = STDIN.gets.chomp.downcase
              end
              config_file_name = File.expand_path("~/#{a.nil? || a.empty? ? path_setup_file : a}")
              old_config = File.read(config_file_name)
              new_config = old_config.dup
              new_config.gsub! /\n*# BEGIN Ruboto PATH setup\n.*?\n# END Ruboto PATH setup\n*/m, ''
              new_config << "\n\n# BEGIN Ruboto PATH setup\n"
              (@existing_paths + @missing_paths - %w(/usr/bin)).uniq.sort.each { |path| new_config << %Q{export PATH="#{path}:$PATH"\n} }
              new_config << "# END Ruboto PATH setup\n\n"
              File.open(config_file_name, 'wb') { |f| f << new_config }
              puts 'Path updated. Please close your command window and reopen.'
            end
          end
        end
      end
    end
  end
end
