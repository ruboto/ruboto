require 'ruboto/sdk_versions'
require 'ruboto/util/verify'

module Ruboto
  module Util
    module Setup
      include Ruboto::Util::Verify
      REPOSITORY_BASE = 'https://dl-ssl.google.com/android/repository'
      REPOSITORY_URL = "#{REPOSITORY_BASE}/repository-8.xml"

      #########################################
      #
      # Core Set up Method
      #

      def setup_ruboto(accept_all, api_levels = [SdkVersions::DEFAULT_TARGET_SDK])
        @platform_sdk_loc = {}
        api_levels = [project_api_level, *api_levels].compact.uniq
        install_all(accept_all, api_levels) unless check_all(api_levels)
        config_path(accept_all)
      end

      #
      # OS independent "which"
      # From: http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      #
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
          end
        end
        nil
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
        when /linux/ then
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
          ENV['ANDROID_HOME'] ? ENV['ANDROID_HOME'] : File.join(File.expand_path('~'), "android-sdk-#{android_package_os_id}")
        end
      end

      def path_setup_file
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/ then
          '.profile'
        when /linux/ then
          '.bashrc'
        when /^mswin32|windows(.*)/ then
          'windows'
          ## Error
        else
          ## Error
          nil
        end
      end

      def get_tools_version(type="tool")
        require 'rexml/document'
        require 'open-uri'

        doc = REXML::Document.new(open(REPOSITORY_URL))
        version = doc.root.elements["sdk:#{type}/sdk:revision/sdk:major"].text
        minor = doc.root.elements["sdk:#{type}/sdk:revision/sdk:minor"]
        micro = doc.root.elements["sdk:#{type}/sdk:revision/sdk:micro"]
        version += ".#{minor.text}" if minor
        version += ".#{micro.text}" if micro
        version
      end

      #########################################
      #
      # Check Methods
      #

      def check_all(api_levels)
        @existing_paths = []
        @missing_paths = []

        @java_loc = check_for('java', 'Java runtime')
        @javac_loc = check_for('javac', 'Java Compiler')
        @ant_loc = check_for('ant', 'Apache ANT')
        check_for_android_sdk
        check_for_emulator
        check_for_platform_tools
        check_for_build_tools
        api_levels.each { |api_level| check_for_android_platform(api_level) }

        puts
        ok = @java_loc && @javac_loc && @ant_loc && @android_loc && @emulator_loc && @adb_loc && @dx_loc && @platform_sdk_loc.all? { |_, path| !path.nil? }
        puts "    #{ok ? '*** Ruboto setup is OK! ***' : '!!! Ruboto setup is NOT OK !!!'}\n\n"
        ok
      end

      def check_for_emulator
        @emulator_loc = check_for('emulator', 'Android Emulator',
                                  File.join(android_package_directory, 'tools', 'emulator'))
      end

      def check_for_platform_tools
        @adb_loc = check_for('adb', 'Android SDK Command adb',
                             File.join(android_package_directory, 'platform-tools', 'adb'))
      end

      def check_for_build_tools
        @dx_loc = check_for('dx', 'Android SDK Command dx',
                            Dir[File.join(android_package_directory, 'build-tools', '*', 'dx')][-1])
      end

      def check_for_android_sdk
        @android_loc = check_for('android', 'Android Package Installer',
                                 File.join(android_package_directory, 'tools', 'android'))
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

        puts "#{'%-25s' % (pretty_name || cmd)}: #{(rv ? 'Found' : 'Not found')}"
        rv
      end

      def check_for_android_platform(api_level)
        begin
          @platform_sdk_loc[api_level] = File.expand_path "#{@android_loc}/../../platforms/#{api_level}"
          found = File.exists? @platform_sdk_loc[api_level]
          @platform_sdk_loc[api_level] = nil unless found
          puts "#{'%-25s' % "Platform SDK #{api_level}"}: #{(found ? 'Found' : 'Not found')}"
        rescue
          @platform_sdk_loc[api_level] = nil
        end
      end

      #########################################
      #
      # Install Methods
      #

      def install_all(accept_all, api_levels)
        install_java(accept_all) unless @java_loc && @javac_loc
        install_ant(accept_all) unless @ant_loc
        install_android_sdk(accept_all) unless @android_loc
        check_all(api_levels)
        install_android_tools(accept_all) unless @dx_loc && @adb_loc && @emulator_loc # build-tools, platform-tools and tools
        if @android_loc
          api_levels.each do |api_level|
            install_platform(accept_all, api_level) unless @platform_sdk_loc[api_level]
          end
        end
      end

      def install_java(accept_all)
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/
        when /linux/
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
        when /linux/
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
                asdk_file_name = "android-sdk_r#{get_tools_version}-#{android_package_os_id}.zip"
                system "wget http://dl.google.com/android/#{asdk_file_name}"
                system "unzip #{'-o ' if accept_all}#{asdk_file_name}"
                system "rm #{asdk_file_name}"
              when /linux/
                asdk_file_name = "android-sdk_r#{get_tools_version}-#{android_package_os_id}.tgz"
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

                asdk_file_name = "installer_r#{get_tools_version}-#{android_package_os_id}.exe"
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
          unless @android_loc.nil?
            ENV['ANDROID_HOME'] = (File.expand_path File.dirname(@android_loc)+"/..").gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
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
            update_cmd = "android --silent update sdk --no-ui --filter build-tools-#{get_tools_version('build-tool')},platform-tool,tool -a --force"
            update_sdk(update_cmd, accept_all)
            check_for_build_tools
            check_for_platform_tools
            check_for_emulator
          end
        end
      end

      def install_platform(accept_all, api_level)
        puts "Android platform SDK for #{api_level} not found."
        unless accept_all
          print 'Would you like to download and install it? (Y/n): '
          a = STDIN.gets.chomp.upcase
        end
        if accept_all || a == 'Y' || a.empty?
          update_cmd = "android update sdk --no-ui --filter #{api_level},sysimg-#{api_level.slice(/\d+$/)} --all"
          update_sdk(update_cmd, accept_all)
          check_for_android_platform(api_level)
        end
      end

      def update_sdk(update_cmd, accept_all)
        if accept_all
          IO.popen(update_cmd, 'r+') do |cmd_io|
            begin
              output = ''
              question_pattern = /.*Do you accept the license '[a-z-]+-[0-9a-f]{8}' \[y\/n\]: /m
              STDOUT.sync = true
              cmd_io.each_char do |text|
                print text
                output << text
                if output =~ question_pattern
                  cmd_io.puts 'y'
                  output.sub! question_pattern, ''
                end
              end
            rescue Errno::EIO
              # This probably just means that the process has finished giving output.
            end
          end
        else
          system update_cmd
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
              rubotorc = '~/.rubotorc'
              File.open(File.expand_path(rubotorc), 'w') do |f|
                (@existing_paths + @missing_paths - %w(/usr/bin)).uniq.sort.each do |path|
                  f << %Q{PATH="#{path}:$PATH"\n}
                end
              end
              config_file_name = File.expand_path("~/#{a.nil? || a.empty? ? path_setup_file : a}")
              old_config = File.read(config_file_name)
              new_config = old_config.dup
              new_config.gsub! /\n*# BEGIN Ruboto setup\n.*?\n# END Ruboto setup\n*/m, ''
              new_config << "\n\n# BEGIN Ruboto setup\n"
              new_config << "source #{rubotorc}\n"
              new_config << "# END Ruboto setup\n\n"
              File.open(config_file_name, 'wb') { |f| f << new_config }
              puts "Updated #{config_file_name} to load the #{rubotorc} config file."
              puts 'Please close your command window and reopen, or run'
              puts
              puts "    source #{rubotorc}"
              puts
            end
          end
        end
      end
    end
  end
end
