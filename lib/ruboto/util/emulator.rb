require 'net/telnet'
require 'ruboto/sdk_versions'
require 'ruboto/sdk_locations'

module Ruboto
  module Util
    module Emulator
      include Ruboto::Util::Verify

      ON_WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw/i)
      ON_MAC_OS_X = RbConfig::CONFIG['host_os'] =~ /^darwin/
      ON_LINUX = RbConfig::CONFIG['host_os'] =~ /linux/
      ON_TRAVIS = ENV['TRAVIS'] == 'true'

      def sdk_level_name(sdk_level)
        Ruboto::SdkVersions::API_LEVEL_TO_VERSION[sdk_level.to_i] || sdk_level
      end

      def start_emulator(sdk_level, no_snapshot)
        sdk_level = sdk_level.gsub(/^android-/, '')
        STDOUT.sync = true
        if RbConfig::CONFIG['host_cpu'] == 'x86_64'
          if ON_MAC_OS_X
            emulator_cmd = '-m "emulator64-(arm|x86)"'
          elsif ON_LINUX
            emulator_cmd = '-r "emulator64-(arm|x86)"'
          else
            emulator_cmd = 'emulator64-arm'
          end
        else
          emulator_cmd = 'emulator-arm'
        end

        emulator_config = verify_ruboto_config['emulator']
        avd_name = (emulator_config && emulator_config['name']) || "Android_#{sdk_level_name(sdk_level)}"
        android_device = (emulator_config && emulator_config['device']) || "Nexus One"
        new_snapshot = false

        if `adb devices` =~ /emulator-5554/
          t = Net::Telnet.new('Host' => 'localhost', 'Port' => 5554, 'Prompt' => /^OK\n|^KO:/)
          t.waitfor(/Android Console:/)
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
            puts "Unexpected response from emulator: #{output.inspect}"
            puts 'Assuming wrong emulator is running.'
          end
        else
          puts 'No emulator is running.'
        end

        # FIXME(uwe):  Change use of "killall" to use the Ruby Process API
        loop do
          emulator_opts = '-partition-size 256'
          emulator_opts << ' -noskin' unless android_device
          emulator_opts << ' -no-snapshot-load' if no_snapshot
          if !ON_MAC_OS_X && !ON_WINDOWS && ENV['DISPLAY'].nil?
            emulator_opts << ' -no-window -no-audio'
          end

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

          avd_home = "#{ENV['HOME'].gsub('\\', '/')}/.android/avd/#{avd_name}.avd"
          manifest_file = 'AndroidManifest.xml'
          large_heap = (!File.exists?(manifest_file)) || (File.read(manifest_file) =~ /largeHeap/)
          heap_size = large_heap ? 256 : 48

          unless File.exists? avd_home
            create_avd(avd_home, avd_name, android_device, heap_size, sdk_level)
            new_snapshot = true
          else
            # FIXME(uwe):  Patch old emulator AVDs.  Remove December 2016.
            patch_config_ini(avd_home, heap_size)
            # EMXIF
          end

          puts "Start emulator #{avd_name}#{' without snapshot' if no_snapshot}"
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
            60.times do
              break if device_ready?
              print '.'
              sleep 1
            end
            puts
            break if device_ready?
            puts 'Emulator started, but failed to respond.'
            unless no_snapshot
              puts 'Retrying without loading snapshot.'
              no_snapshot = true
            end
          else
            puts 'Unable to start the emulator.'
            exit 1 if ON_TRAVIS
          end
        end

        if new_snapshot
          puts 'Allow the emulator to calm down a bit.'
          60.times do
            break if `adb shell ps` =~ /android.process.acore/
            print '.'
            sleep 1
          end
          puts
        end

        system <<EOF
(
  set +e
  for i in {1..10} ; do
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

      def create_avd(avd_home, avd_name, android_device, heap_size, sdk_level)
        puts "Creating AVD #{avd_name}"

        target = `android list target`.split(/----------\n/).
            find { |l| l =~ /android-#{sdk_level}/ }

        if target.nil?
          puts "Target android-#{sdk_level} not found.  You should run"
          puts "\n    ruboto setup -y -t #{sdk_level}\n\nto install it."
          exit 3
        end

        abis = target.slice(/(?<=ABIs : ).*/).split(', ')
        has_x86 = abis.find { |a| a =~ /x86/ }
        has_x86_64 = has_x86 && abis.find { |a| a =~ /x86_64/ }

        # FIXME(uwe): Remove this check when HAXM is available on travis
        # FIXME(uwe): or the x86(_64) emulators don't require HAXM anymore
        # Newer Android SDK tools (V24) require HAXM to run x86 emulators.
        # HAXM is not available on travis-ci.
        if ON_TRAVIS && sdk_level.to_i >= 22
          abi_opt = '--abi armeabi-v7a'
          # EMXIF
        elsif has_x86
          if has_x86_64
            abi_opt = '--abi x86_64'
          else
            abi_opt = '--abi x86'
          end
        else
          abi_opt = '--abi armeabi-v7a'
        end

        ruboto_config_filename = 'ruboto.yml'
        if File.exists?(ruboto_config_filename)
          ruboto_config = YAML.read(ruboto_config_filename)
          skin = ruboto_config['emulator']['skin']
        end
        skin ||= android_device ? nil : 'HVGA'
        # skin_filename = "#{Ruboto::SdkLocations::ANDROID_HOME}/platforms/android-#{sdk_level}/skins/#{skin}/hardware.ini"
        # if File.exists?(skin_filename)
        #   old_skin_config = File.read(skin_filename)
        #   new_skin_config = old_skin_config.gsub(/vm.heapSize=([0-9]*)/) { |m| $1.to_i < heap_size ? "vm.heapSize=#{heap_size}" : m }
        #   add_property(new_skin_config, 'hw.mainKeys', 'no')
        #   add_property(new_skin_config, 'hw.lcd.density', '160')
        #   File.write(skin_filename, new_skin_config) if new_skin_config != old_skin_config
        # end

        puts `echo no | android create avd -a -n #{avd_name} -t android-#{sdk_level} #{abi_opt} -c 64M #{"-s #{skin}" if skin} -d "#{android_device}"`

        if $? != 0
          puts 'Failed to create AVD.'
          exit 3
        end
        patch_config_ini(avd_home, heap_size)

        # hw_config_file_name = "#{avd_home}/hardware-qemu.ini"
        # if File.exists?(hw_config_file_name)
        #   old_hw_config = File.read(hw_config_file_name)
        #   new_hw_config = old_hw_config.gsub(/vm.heapSize=([0-9]*)/) { |m| $1.to_i < heap_size ? "vm.heapSize=#{heap_size}" : m }
        #   File.write(hw_config_file_name, new_hw_config) if new_hw_config != old_hw_config
        # end
      end

      def patch_config_ini(avd_home, heap_size)
        avd_config_file_name = "#{avd_home}/config.ini"
        old_avd_config = File.read(avd_config_file_name)
        new_avd_config = old_avd_config.dup
        new_avd_config.gsub!(/vm.heapSize=([0-9]*)/) do |m|
          if $1.to_i < heap_size
            puts "Changed property: vm.heapSize=#{heap_size} (was #{$1})"
            "vm.heapSize=#{heap_size}"
          else
            m
          end
        end
        # add_property(new_avd_config, 'hw.device.manufacturer', 'Generic')
        # add_property(new_avd_config, 'hw.device.name', '3.2" HVGA slider (ADP1)')
        # add_property(new_avd_config, 'hw.keyboard.lid', 'no')
        add_property(new_avd_config, 'hw.lcd.density', '160')
        add_property(new_avd_config, 'hw.mainKeys', 'no')
        # add_property(new_avd_config, 'hw.sdCard', 'yes')
        File.write(avd_config_file_name, new_avd_config) if new_avd_config != old_avd_config
      end

      def device_ready?
        `adb get-state`.gsub(/^WARNING:.*$/, '').chomp == 'device'
      end

      def add_property(new_avd_config, property_name, value)
        pattern = /^#{property_name}=(.*)$/
        property = "#{property_name}=#{value}"
        if new_avd_config =~ pattern
          if $1 != value
            new_avd_config.gsub! pattern, property
            puts "Changed property: #{property}"
          end
        else
          new_avd_config << "#{property}\n"
          puts "Added property: #{property}"
        end
      end
    end
  end
end
