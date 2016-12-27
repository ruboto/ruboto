require 'ruboto/sdk_versions'
require 'ruboto/util/verify'

module Ruboto
  module Util
    module Setup
      include Ruboto::Util::Verify
      REPOSITORY_BASE = 'http://dl-ssl.google.com/android/repository'
      REPOSITORY_URL = "#{REPOSITORY_BASE}/repository-10.xml"
      ADDONS_URL = "#{REPOSITORY_BASE}/extras/intel/addon.xml"
      SDK_DOWNLOAD_PAGE = 'https://developer.android.com/studio/index.html'

      RUBOTO_GEM_ROOT = File.expand_path '../../../..', __FILE__
      WINDOWS_ELEVATE_CMD = "#{RUBOTO_GEM_ROOT}/bin/elevate_32.exe -c -w"

      #########################################
      #
      # Core Set up Method
      #

      def setup_ruboto(accept_all, api_levels = [SdkVersions::DEFAULT_TARGET_SDK], upgrade_haxm = false)
        @platform_sdk_loc = {}
        api_levels = [project_api_level, *api_levels].compact.uniq
        install_all(accept_all, api_levels, upgrade_haxm) unless check_all(api_levels, upgrade_haxm)
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
            if File.executable?(exe) and not File.directory?(exe)
              exe.gsub!('\\', '/') if windows?
              return exe
            end
          end
        end
        nil
      end

      private

      #########################################
      #
      # Utility Methods
      #

      MAC_OS_X = 'macosx'
      WINDOWS = 'windows'
      LINUX = 'linux'

      def android_package_os_id
        case RbConfig::CONFIG['host_os']
        when /^darwin(.*)/
          MAC_OS_X
        when /linux/
          LINUX
        when /^mswin32|windows|mingw32/
          WINDOWS
        else
          ## Error
          nil
        end
      end

      def mac_os_x?
        android_package_os_id == MAC_OS_X
      end

      def windows?
        android_package_os_id == WINDOWS
      end

      def android_package_directory
        return ENV['ANDROID_HOME'] if ENV['ANDROID_HOME']
        File.join File.expand_path('~'), windows? ? 'AppData/Local/Android/android-sdk' : "android-sdk-#{android_package_os_id}"
      end

      def android_haxm_directory
        Dir[File.join(android_package_directory, 'extras', 'intel', 'Hardware_Accelerated_Execution_Manager')][0]
      end

      def package_installer
        case android_package_os_id
        when LINUX
          which('apt-get') or which('yum')
        else
          ## Error
          nil
        end
      end

      def path_setup_file
        case android_package_os_id
        when MAC_OS_X
          '.profile'
        when LINUX
          '.bashrc'
        when WINDOWS
          ## Error
          'windows'
        else
          ## Error
          nil
        end
      end

      def get_tools_version(type='tool', repo_url = REPOSITORY_URL, host_os = nil)
        require 'rexml/document'
        require 'open-uri'

        doc = REXML::Document.new(open(repo_url))
        doc.root.elements.to_a("sdk:#{type}").map do |t|
          r = t.elements['sdk:revision']
          major = r.elements['sdk:major']
          minor = r.elements['sdk:minor']
          micro = r.elements['sdk:micro']
          prev = r.elements['sdk:preview']
          next if prev
          url = t.elements['sdk:archives/sdk:archive/sdk:url'].text
          pkg_host_os = t.elements['sdk:archives/sdk:archive/sdk:host-os'].text
          next if host_os && pkg_host_os != host_os
          version = major.text
          version += ".#{minor.text}" if minor
          version += ".#{micro.text}" if micro
          version += "_rc#{prev.text}" if prev
          [version, url]
        end.compact.sort_by { |v| Gem::Version.new(v[0].gsub('_', '.')) }.last
      end

      def get_android_sdk_version
        require 'net/http'
        require 'uri'

        # Get's the Page to Scrape
        page_content = Net::HTTP.get(URI.parse(SDK_DOWNLOAD_PAGE))

        case android_package_os_id
        when MAC_OS_X
          regex = '(\>android-sdk.*macosx.zip)'
        when LINUX
          regex = '(\>android-sdk.*.tgz)'
        when WINDOWS
          regex = '(\>installer_.*.exe)'
        else
          raise "Unknown host os: #{android_package_os_id}"
        end

        link = page_content.scan(/#{regex}/)
        raise "SDK link cannot be found on download page: #{SDK_DOWNLOAD_PAGE}" if link.nil?

        version = link.to_s.match(/r(\d+.)?(\d+.)?(\d+)/)[0]
        raise "SDK version cannot be determined from download page: #{SDK_DOWNLOAD_PAGE}" if version.nil?

        version.delete! 'r'
      end

      #########################################
      #
      # Check Methods
      #

      def check_all(api_levels, update = false)
        @existing_paths ||= []
        @missing_paths ||= []

        @java_loc = check_for('java', 'Java runtime', ENV['JAVA_HOME'] && "#{ENV['JAVA_HOME']}/bin/java")
        @javac_loc = check_for('javac', 'Java Compiler', ENV['JAVA_HOME'] && "#{ENV['JAVA_HOME']}/bin/javac")
        @ant_loc = check_for('ant', 'Apache ANT')
        check_for_android_sdk
        check_for_emulator
        check_for_haxm
        check_for_platform_tools
        check_for_build_tools
        api_levels.each { |api_level| check_for_android_platform(api_level) }

        @existing_paths.uniq!
        @missing_paths.uniq!

        puts
        ok = @java_loc && @javac_loc && @ant_loc && @android_loc && @emulator_loc && haxm_ok?(update) &&
            @adb_loc && @dx_loc && @platform_sdk_loc.all? { |_, path| !path.nil? }
        puts "    #{ok ? '*** Ruboto setup is OK! ***' : '!!! Ruboto setup is NOT OK !!!'}\n\n"
        ok
      end

      def haxm_ok?(update)
        @haxm_kext_loc && !(update && haxm_old?)
      end

      def haxm_old?
        @haxm_kext_version != @haxm_installer_version
      end

      def check_for_emulator
        @emulator_loc = check_for('emulator', 'Android Emulator',
                                  File.join(android_package_directory, 'tools', 'emulator'))
      end

      def check_for_haxm
        case android_package_os_id
        when MAC_OS_X
          @haxm_kext_loc = '/Library/Extensions/intelhaxm.kext'
          found = File.exist?(@haxm_kext_loc)

          # FIXME(uwe): Remove when we stop supporting old HAXM installer versions, like mid 2016.
          unless found
            @haxm_kext_loc = '/System/Library/Extensions/intelhaxm.kext'
            found = File.exist?(@haxm_kext_loc)
          end
          # EMXIF

          if found
            @haxm_kext_version = `kextstat | grep com.intel.kext.intelhaxm`.slice(/\(.*\)/)[1..-2]
          else
            @haxm_kext_loc = nil
          end

          @haxm_installer_loc = Dir[File.join(android_package_directory, 'extras', 'intel', 'Hardware_Accelerated_Execution_Manager', 'IntelHAXM_*.dmg')][0]

          # FIXME(uwe): Remove when we stop supporting old HAXM installer versions, like mid 2016.
          if @haxm_installer_loc.nil?
            os_x_version = `sw_vers -productVersion`
            if Gem::Version.new(os_x_version) > Gem::Version.new('10.9')
              @haxm_installer_loc = Dir[File.join(android_package_directory, 'extras', 'intel', 'Hardware_Accelerated_Execution_Manager', 'IntelHAXM*_above*.dmg')][0]
            else
              @haxm_installer_loc = Dir[File.join(android_package_directory, 'extras', 'intel', 'Hardware_Accelerated_Execution_Manager', 'IntelHAXM*_below*.dmg')][0]
            end
          end
          # EMXIF

          @haxm_installer_version = File.basename(@haxm_installer_loc).scan(/\d+/).join('.') unless @haxm_installer_loc.nil? || @haxm_installer_loc.empty?
          if haxm_old?
            puts "#{'%-25s' % 'Intel HAXM'}: Old   #{@haxm_kext_version}/#{@haxm_installer_version}"
          else
            puts "#{'%-25s' % 'Intel HAXM'}: #{(found ? 'Found' : 'Not found')}"
          end
        when LINUX
          @haxm_installer_loc = 'Not supported, yet.'
          @haxm_kext_loc = 'Not supported, yet.'
          return
        when WINDOWS
          @haxm_kext_loc = `sc query intelhaxm`
          found = ($? == 0)
          @haxm_kext_loc = nil unless found
          puts "#{'%-25s' % 'Intel HAXM'}: #{(found ? 'Found' : 'Not found')}"
          @haxm_installer_loc = Dir[File.join(android_package_directory, 'extras', 'intel', 'Hardware_Accelerated_Execution_Manager', 'IntelHaxm*.exe')].first
          return
        end
      end

      def check_for_platform_tools
        @adb_loc = check_for('adb', 'Android SDK Command adb',
                             File.join(android_package_directory, 'platform-tools', windows? ? 'adb.exe' : 'adb'))
      end

      def check_for_build_tools
        dx_locations = Dir[File.join android_package_directory, 'build-tools', '*', windows? ? 'dx.bat' : 'dx']
        sorted_dx_locations = dx_locations.sort_by { |f| Gem::Version.new f[%r{build-tools/[^/]+/(\d{1,}[.]){2}\d{1,}(_rc\d)?}]}
        @dx_loc = check_for('dx', 'Android SDK Command dx', sorted_dx_locations[-1])
      end

      def check_for_android_sdk
        @android_loc = check_for('android', 'Android Package Installer',
                                 File.join(android_package_directory, 'tools', windows? ? 'android.bat' : 'android'))
      end

      def check_for(cmd, pretty_name=nil, alt_dir=nil)
        rv = which(cmd)
        rv = nil if rv && rv.empty?

        if rv
          @existing_paths << File.dirname(rv)
        elsif alt_dir && File.exist?(alt_dir)
          rv = alt_dir
          if windows?
            ENV['PATH'] = "#{File.dirname(rv).gsub('/', '\\')};#{ENV['PATH']}"
          else
            ENV['PATH'] = "#{File.dirname(rv)}:#{ENV['PATH']}"
          end
          @missing_paths << "#{File.dirname(rv)}"
        end

        puts "#{'%-25s' % (pretty_name || cmd)}: #{(rv ? 'Found' : 'Not found')}"
        rv
      end

      def check_for_android_platform(api_level)
        @platform_sdk_loc[api_level] = File.expand_path "#{android_package_directory}/platforms/#{api_level}"
        found = File.exist? @platform_sdk_loc[api_level]
        @platform_sdk_loc[api_level] = nil unless found
        puts "#{'%-25s' % "Platform SDK #{api_level}"}: #{(found ? 'Found' : 'Not found')}"
      rescue
        @platform_sdk_loc[api_level] = nil
      end

      #########################################
      #
      # Install Methods
      #

      def install_all(accept_all, api_levels, upgrade_haxm)
        install_java(accept_all) unless @java_loc && @javac_loc
        install_ant(accept_all) unless @ant_loc
        install_android_sdk(accept_all) unless @android_loc

        # build-tools, platform-tools, tools, and haxm
        install_android_tools(accept_all) unless @dx_loc && @adb_loc && @emulator_loc && @haxm_installer_loc
        install_haxm(accept_all) unless haxm_ok?(upgrade_haxm)
        # download_and_upgrade_haxm(true) if upgrade_haxm

        if @android_loc
          api_levels.each do |api_level|
            install_platform(accept_all, api_level) unless @platform_sdk_loc[api_level]
          end
        end
        check_all(api_levels)
      end

      def install_package(accept_all, package_name, pretty_name)
        case android_package_os_id
        when LINUX
          puts "#{pretty_name} was not found."
          installer = package_installer
          if installer
            unless accept_all
              print 'Would you like to and install it? (Y/n): '
              a = STDIN.gets.chomp.upcase
            end
            if accept_all || a == 'Y' || a.empty?
              puts "sudo #{installer} install -y #{package_name}"
              IO.popen("sudo #{installer} install -y #{package_name}") do |io|
                while (l = io.gets)
                  puts l
                end
              end
            else
              puts
              puts "You can install #{pretty_name} manually by:"
              puts "sudo #{installer} install #{package_name}"
              puts
            end
          else
            puts "Package installer not found. You'll need to install #{pretty_name} manually."
          end
        else
          raise "Unknown host os for package install: #{RbConfig::CONFIG['host_os']}"
        end
      end

      def install_java(accept_all)
        case android_package_os_id
        when MAC_OS_X
        when LINUX
          install_package(accept_all, 'default-jdk', 'Default Java Development Kit')
        when WINDOWS
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
            raise "Unexpected exit code while installing Java: #{$?.exitstatus}" unless $? == 0
            FileUtils.rm_f java_installer_file_name
          else
            puts
            puts 'You can download and install the Java JDK manually from'
            puts 'http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html'
            puts
          end
          unless check_for('javac')
            ENV['JAVA_HOME'] = 'c:\\Program Files\\Java\\jdk1.7.0'
            if Dir.exist?(ENV['JAVA_HOME'])
              @javac_loc = "#{ENV['JAVA_HOME'].gsub('\\', '/')}/bin/javac"
              puts "Setting the JAVA_HOME environment variable to #{ENV['JAVA_HOME']}"
              system %Q{setx JAVA_HOME "#{ENV['JAVA_HOME']}"}
              @missing_paths << "#{File.dirname(@javac_loc)}"
            end
          end
        else
          raise "Unknown host os: #{android_package_os_id}"
        end
      end

      def install_ant(accept_all)
        case android_package_os_id
        when MAC_OS_X
        when LINUX
          install_package(accept_all, 'ant', 'Apache ANT')
        when WINDOWS
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
            if Dir.exist?(ENV['ANT_HOME'])
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
              case android_package_os_id
              when MAC_OS_X
                asdk_file_name = "android-sdk_r#{get_android_sdk_version}-#{android_package_os_id}.zip"
                download(asdk_file_name)
                unzip(accept_all, asdk_file_name)
                FileUtils.rm_f asdk_file_name
              when LINUX
                asdk_file_name = "android-sdk_r#{get_android_sdk_version}-#{android_package_os_id}.tgz"
                download asdk_file_name
                system "tar -xzf #{asdk_file_name}"
                FileUtils.rm_f asdk_file_name
              when WINDOWS
                # FIXME(uwe):  Detect and warn if we are not "elevated" with adminstrator rights.
                #set IS_ELEVATED=0
                #whoami /groups | findstr /b /c:"Mandatory Label\High Mandatory Level" | findstr /c:"Enabled group" > nul: && set IS_ELEVATED=1
                #if %IS_ELEVATED%==0 (
                #    echo You must run the command prompt as administrator to install.
                #    exit /b 1
                #)

                asdk_file_name = "installer_r#{get_android_sdk_version}-#{android_package_os_id}.exe"
                download(asdk_file_name)
                puts "Installing #{asdk_file_name}..."
                system "#{WINDOWS_ELEVATE_CMD} #{asdk_file_name}"
                raise "Unexpected exit code while installing the Android SDK: #{$?.exitstatus}" unless $? == 0
                FileUtils.rm_f asdk_file_name
                return
              else
                raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
              end
            end
          end
          check_for_android_sdk
          unless @android_loc.nil?
            ENV['ANDROID_HOME'] = (File.expand_path File.dirname(@android_loc)+'/..').gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)
            puts "Setting the ANDROID_HOME environment variable to #{ENV['ANDROID_HOME']}"
            if windows?
              system %Q{setx ANDROID_HOME "#{ENV['ANDROID_HOME']}"}
            end
            @missing_paths << "#{File.dirname(@android_loc)}"
          end
        end
      end

      def download_third_party(filename, uri)
        print "Downloading #{uri}/#{filename} \r"
        uri = URI("#{uri}/#{filename}")
        puts "File will be saved to #{android_haxm_directory}/#{filename}"
        process_download("#{android_haxm_directory}/#{filename}", uri)
      end

      def process_download(filename, uri)
        body = ''
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https').request_get(uri.path) do |response|
          length = response['Content-Length'].to_i
          response.read_body do |fragment|
            body << fragment
            print "Downloading #{filename}: #{body.length / 1024**2}MB/#{length / 1024**2}MB #{(body.length * 100) / length}%\r"
          end
        end
        File.open(filename, 'wb') { |f| f << body }
      end


      def download(asdk_file_name)
        print "Downloading #{asdk_file_name}: \r"
        uri = URI("http://dl.google.com/android/#{asdk_file_name}")
        process_download(asdk_file_name, uri)
      end


      def unzip(accept_all, asdk_file_name, extract_to='.')
        require 'zip'
        Zip::File.open(asdk_file_name) do |zipfile|
          zipfile.each do |f|
            f.restore_permissions = true
            f.extract("#{extract_to}/#{f.name}") { accept_all }
          end
        end
      end

      def install_android_tools(accept_all)
        if @android_loc and (@dx_loc.nil? || @adb_loc.nil? || @emulator_loc.nil? || @haxm_installer_loc.nil?)
          puts 'Android tools not found.'
          unless accept_all
            print 'Would you like to download and install them? (Y/n): '
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            android_cmd = windows? ? 'android.bat' : 'android'
            update_cmd = "#{android_cmd} --silent update sdk --no-ui --filter build-tools-#{get_tools_version('build-tool')[0]},extra-intel-Hardware_Accelerated_Execution_Manager,platform-tool,tool -a"
            update_sdk(update_cmd, accept_all)
            check_for_build_tools
            check_for_platform_tools
            check_for_emulator
            check_for_haxm
          end
        end
      end

      def get_new_haxm_filename
        case android_package_os_id
        when MAC_OS_X, WINDOWS
          version, file_name = get_tools_version('extra', ADDONS_URL, android_package_os_id)
        when LINUX
          puts 'HAXM installation on Linux is not supported, yet.'
          file_name = version = ''
        else
          raise "Unknown host os: #{RbConfig::CONFIG['host_os']}"
        end

        return file_name, version
      end

      def download_haxm(accept_all, haxm_file_name)
        download_third_party(haxm_file_name, ADDONS_URL)
        unzip(accept_all, "#{android_haxm_directory}/#{haxm_file_name}", "#{android_haxm_directory}")
        FileUtils.rm_f "#{android_haxm_directory}/#{haxm_file_name}"
      end

      def download_and_upgrade_haxm(accept_all)
        print "Downloading Intel HAXM... \r"
        filename, version = get_new_haxm_filename
        download_haxm(accept_all, filename)
        install_haxm(accept_all, version)
      end

      def install_haxm(accept_all, custom_version=nil)
        haxm_file_override =  "IntelHAXM_#{custom_version}.dmg" unless custom_version.nil?
        if @haxm_installer_loc && (@haxm_kext_loc.nil? || haxm_old?)
          if @haxm_kext_loc.nil?
            puts 'HAXM not installed.'
          else
            puts "HAXM is old: #{@haxm_kext_version} / #{@haxm_installer_version}"
          end

          unless accept_all
            if @haxm_kext_loc.nil?
              print 'Would you like to install HAXM? (Y/n): '
            else
              print 'Would you like to update HAXM? (Y/n): '
            end
            a = STDIN.gets.chomp.upcase
          end
          if accept_all || a == 'Y' || a.empty?
            case android_package_os_id
            when MAC_OS_X
              puts 'Mounting the HAXM install image'
              if custom_version.nil?
                system "hdiutil attach #{@haxm_installer_loc}"
                fileName = Dir['/Volumes/IntelHAXM*/IntelHAXM*.mpkg'][0]
              else
                system "hdiutil attach #{android_haxm_directory}/#{haxm_file_override}"
                fileName = Dir["/Volumes/IntelHAXM_#{custom_version}/IntelHAXM_#{custom_version}.mpkg"][0]
              end
              puts 'Starting the HAXM installer.  Sudo password required.'
              system "sudo -S installer -pkg #{fileName} -target /"
            when LINUX
              puts '    HAXM installation on Linux is not supported, yet.'
              return
            when WINDOWS
              cmd = @haxm_installer_loc.gsub('/', "\\")
              puts 'Running the HAXM installer'
              system %Q{#{WINDOWS_ELEVATE_CMD} "#{cmd}"}
              raise "Unexpected return code: #{$?.exitstatus}" unless $? == 0
              return
            end
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
          android_cmd = windows? ? 'android.bat' : 'android'

          # FIXME: (uwe) Change to only install the best image for this system corresponding to the abi chosen when creating an emulator
          level = api_level[/\d+/]
          arches = %w(x86 x86_64 armeabi-v7a arm64-v8a)
          arches -= %w(x86 x86_64) if ON_TRAVIS && level.to_i >= 22 # TODO: (uwe) Remove when travis can run x86 images
          abi_list = arches.product(%w(android google_apis))
              .map{|arch, vendor| "sys-img-#{arch}-#{vendor}-#{level}"}
          puts "Installing #{abi_list}"
          update_cmd = "#{android_cmd} update sdk --no-ui --filter #{api_level},#{abi_list.join(',')} --all"
          # EMXIF

          update_sdk(update_cmd, accept_all)
          check_for_android_platform(api_level)
        end
      end

      def update_sdk(update_cmd, accept_all)
        if accept_all
          IO.popen(update_cmd, 'r+', external_encoding: Encoding::BINARY) do |cmd_io|
            begin
              output = ''.encode(Encoding::BINARY)
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
          puts "\nYou are missing some paths.  Execute these lines to add them:\n\n"
          if windows?
            @missing_paths.each do |path|
              puts %Q{    set PATH="#{path.gsub '/', '\\'};%PATH%"}
            end
            old_path = ENV['PATH'].split(';')
            new_path = (@missing_paths.map { |path| path.gsub '/', '\\' } + old_path).uniq.join(';')
            if new_path.size <= 1024
              system %Q{setx PATH "#{new_path}"}
            else
              puts "\nYour path is HUGE:  #{new_path.size} characters.  It cannot be saved permanently:\n\n"
              puts new_path.gsub(';', "\n")
              puts
            end
          else
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
              unless File.exist? config_file_name
                puts "Your path configuration script (#{config_file_name}) does not exist, Ruboto will create a new one."
                system "touch #{config_file_name}"
              end

              old_config = File.read(config_file_name)
              new_config = old_config.dup
              new_config.gsub! /\n*# BEGIN Ruboto setup\n.*?\n# END Ruboto setup\n*/m, "\n\n"
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
