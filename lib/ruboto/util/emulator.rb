require 'net/telnet'

module Ruboto
  module Util
    module Emulator
      ON_WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/i)
      ON_MAC_OS_X = RbConfig::CONFIG['host_os'] =~ /^darwin(.*)/

      API_LEVEL_TO_VERSION = {
          10 => '2.3.3', 11 => '3.0', 12 => '3.1', 13 => '3.2', 14 => '4.0',
          15 => '4.0.3', 16 => '4.1.2', 17 => '4.2.2', 18 => '4.3',
      }

      def sdk_level_name(sdk_level)
        API_LEVEL_TO_VERSION[sdk_level]
      end

      def start_emulator(sdk_level)
        sdk_level = sdk_level.gsub(/^android-/, '').to_i
        STDOUT.sync = true
        if RbConfig::CONFIG['host_cpu'] == 'x86_64'
          if ON_MAC_OS_X
            emulator_cmd = '-m "emulator64-(arm|x86)"'
          else
            emulator_cmd = 'emulator64-arm'
          end
        else
          emulator_cmd = 'emulator-arm'
        end

        emulator_opts = '-partition-size 256'
        if !ON_WINDOWS && ENV['DISPLAY'].nil?
          emulator_opts << ' -no-window -no-audio'
        end

        avd_name = "Android_#{sdk_level_name(sdk_level)}"
        new_snapshot = false

        if `adb devices` =~ /emulator-5554/
          t = Net::Telnet.new('Host' => 'localhost', 'Port' => 5554, 'Prompt' => /^OK\n/)
          t.waitfor(/^OK\n/)
          output = ''
          t.cmd('avd name') { |c| output << c }
          t.close
          if output =~ /(.*)\nOK\n/
            running_avd_name = $1
            if running_avd_name == avd_name
              puts "Emulator #{avd_name} is already running."
              return
            else
              puts "Emulator #{running_avd_name} is running."
            end
          else
            raise "Unexpected response from emulator: #{output.inspect}"
          end
        else
          puts 'No emulator is running.'
        end

        # FIXME(uwe):  Change use of "killall" to use the Ruby Process API
        loop do
          `killall -0 #{emulator_cmd} 2> /dev/null`
          if $? == 0
            `killall #{emulator_cmd}`
            10.times do |i|
              `killall -0 #{emulator_cmd} 2> /dev/null`
              if $? != 0
                break
              end
              if i == 3
                print 'Waiting for emulator to die: ...'
              elsif i > 3
                print '.'
              end
              sleep 1
            end
            puts
            `killall -0 #{emulator_cmd} 2> /dev/null`
            if $? == 0
              puts 'Emulator still running.'
              `killall -9 #{emulator_cmd}`
              sleep 1
            end
          end

          if [17, 16, 15, 13, 11].include? sdk_level
            abi_opt = '--abi armeabi-v7a'
          elsif sdk_level == 10
            abi_opt = '--abi armeabi'
          end

          avd_home = "#{ENV['HOME'].gsub('\\', '/')}/.android/avd/#{avd_name}.avd"
          unless File.exists? avd_home
            puts "Creating AVD #{avd_name}"
            if ON_MAC_OS_X
              abis = `android list target`.split(/----------\n/).
                  find{ |l| l =~ /android-#{sdk_level}/ }.slice(/(?<=ABIs : ).*/).split(', ')
              abi = abis.find { |a| a =~ /x86/ }
            end
            puts `echo n | android create avd -a -n #{avd_name} -t android-#{sdk_level} #{abi_opt} -c 64M -s HVGA #{"--abi #{abi}" if abi}`
            if $? != 0
              puts 'Failed to create AVD.'
              exit 3
            end
            avd_config_file_name = "#{avd_home}/config.ini"
            old_avd_config = File.read(avd_config_file_name)
            manifest_file = 'AndroidManifest.xml'
            heap_size = (File.exists?(manifest_file) && File.read(manifest_file) =~ /largeHeap/) ? 256 : 48
            new_avd_config = old_avd_config.gsub(/vm.heapSize=([0-9]*)/) { |m| p m; m.to_i < heap_size ? "vm.heapSize=#{heap_size}" : m }
            File.write(avd_config_file_name, new_avd_config) if new_avd_config != old_avd_config
            new_snapshot = true
          end

          puts 'Start emulator'
          system "emulator -avd #{avd_name} #{emulator_opts} #{'&' unless ON_WINDOWS}"
          return if ON_WINDOWS

          3.times do |i|
            sleep 1
            `killall -0 #{emulator_cmd} 2> /dev/null`
            if $? == 0
              break
            end
            if i == 3
              print 'Waiting for emulator: ...'
            elsif i > 3
              print '.'
            end
          end
          puts
          `killall -0 #{emulator_cmd} 2> /dev/null`
          if $? != 0
            puts 'Unable to start the emulator.  Retrying without loading snapshot.'
            system "emulator -no-snapshot-load -avd #{avd_name} #{emulator_opts} #{'&' unless ON_WINDOWS}"
            10.times do |i|
              `killall -0 #{emulator_cmd} 2> /dev/null`
              if $? == 0
                new_snapshot = true
                break
              end
              if i == 3
                print 'Waiting for emulator: ...'
              elsif i > 3
                print '.'
              end
              sleep 1
            end
          end

          `killall -0 #{emulator_cmd} 2> /dev/null`
          if $? == 0
            print 'Emulator started: '
            50.times do
              if `adb get-state`.chomp == 'device'
                break
              end
              print '.'
              sleep 1
            end
            puts
            if `adb get-state`.chomp == 'device'
              break
            end
          end
          puts 'Unable to start the emulator.'
        end

        if new_snapshot
          puts 'Allow the emulator to calm down a bit.'
          sleep 15
        end

        system <<EOF
(
  set +e
  for i in 1 2 3 4 5 6 7 8 9 10 ; do
    sleep 6
    adb shell input keyevent 82 >/dev/null 2>&1
    if [ "$?" = "0" ] ; then
      set -e
      adb shell input keyevent 82 >/dev/null 2>&1
      adb shell input keyevent 4 >/dev/null 2>&1
      exit 0
    fi
  done
  echo "Failed to unlock screen"
  set -e
  exit 1
) &
EOF
        system 'adb logcat > adb_logcat.log &'

        puts "Emulator #{avd_name} started OK."
      end
    end
  end
end
