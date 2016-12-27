######################################
#
# Methods for package installation
#

# Android 7.1: -rw-r--r-- 1 system system 9462614 2016-11-24 13:20 /data/app/org.ruboto.test_app-1/base.apk
# Android 6.0: -rw-r--r-- system   system    9462797 2016-11-24 13:05 base.apk
APK_FILE_REGEXP = /^-rw-r--r--(?:\s+\d+)?\s+(?:system|\d+\s+\d+)\s+(?:system|\d+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}|\w{3} \d{2}\s+(?:\d{4}|\d{2}:\d{2}))\s+(.*)$/
PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
UPDATE_MARKER_FILE = File.join(PROJECT_DIR, 'bin', 'LAST_UPDATE')

# Determine if the package is installed.
# Return true if the package is installed and is identical to the local package.
# Return false if the package is installed, but differs from the local package.
# Return nil if the package is not installed.
def package_installed?(package_name, apk_file)
  loop do
    path_line = `adb shell pm path #{package_name}`.chomp
    path_line.gsub! /^WARNING:.*$/, ''
    return nil if $? != 0 || path_line.empty?
    break if path_line =~ /^package:(.*)$/
    puts path_line
    sleep 0.5
  end
  path = $1
  o = `adb shell ls -l #{path}`.chomp
  raise "Unexpected ls output: #{o}" unless o =~ APK_FILE_REGEXP
  installed_apk_size = $1.to_i
  installed_timestamp = Time.parse($2)
  !File.exists?(apk_file) || (installed_apk_size == File.size(apk_file) &&
      installed_timestamp >= File.mtime(apk_file))
end

# the scripts path is different on different Android versions and devices...
def scripts_path(package)
  external_storage = `adb shell 'echo $EXTERNAL_STORAGE'`.chomp
  app_data_path = "#{external_storage}/Android/data/#{package}"
  if external_storage.empty?
    puts "external storage not found: #{app_data_path.inspect}"
    app_data_path = `adb shell run-as #{package} pwd`
    if app_data_path =~ /Permission denied/
      puts "internal storage not found: #{app_data_path.inspect}"
      app_data_path = "/mnt/sdcard/Android/data/#{package}"
    end
  end
  "#{app_data_path}/files/scripts"
end

def mark_update(time = Time.now)
  FileUtils.mkdir_p File.dirname(UPDATE_MARKER_FILE)
  File.open(UPDATE_MARKER_FILE, 'w') { |f| f << time.iso8601 }
end

def clear_update(package, apk_file)
  mark_update File.ctime apk_file
  if device_path_exists?(scripts_path(package))
    sh "adb shell rm -r #{scripts_path(package)}"
    puts "Deleted scripts directory #{scripts_path(package)}"
  end
end

def device_path_exists?(path)
  path_output = `adb shell ls #{path} 2>&1`.chomp
  path_output.empty? || path_output !~ /No such file or directory|opendir failed, Permission denied/
end

def wait_for_valid_device
  while `adb shell echo "ping"`.strip != 'ping'
    `adb kill-server`
    `adb devices`
    sleep 5
  end
end

# Synchronize device system time with development system time.
def set_device_time
  # TODO: (uwe) Remove when we stop supporting Android 6.0 and older
  if sdk_level <= 23
    return sh "adb shell date -s #{Time.now.strftime '%Y%m%d.%H%M%S'}"
  end
  # ODOT

  sh "adb shell date +'%Y%m%d.%H%M%S' #{Time.now.strftime '%Y%m%d.%H%M%S'}"
end

def install_apk(package, apk_file)
  wait_for_valid_device
  failure_pattern = /^Failure \[(.*)\]/
  success_pattern = /^Success/
  install_timeout = 5 * 60
  case package_installed?(package, apk_file)
  when true
    puts "Package #{package} already installed."
    return
  when false
    puts "Package #{package} already installed, but of different size or timestamp."
    replace_apk = true
  else
    # Package not installed.
  end

  set_device_time
  output = nil
  5.times do |install_retry_count|
    if install_retry_count > 0
      puts output
      puts 'Retrying install...'
    end
    # replace_apk ||= install_retry_count >= 3
    puts "#{replace_apk ? 'Replacing' : 'Installing'} package #{package}"

    install_start = Time.now
    begin
      Timeout.timeout install_timeout do
        output = `adb install #{'-r' if replace_apk} "#{apk_file}" 2>&1`
      end
    rescue Timeout::Error
      puts "Installing package #{package} timed out after #{install_timeout}s."
      next
    end

    if $? == 0 && output !~ failure_pattern && output =~ success_pattern
      puts "Install took #{(Time.now - install_start).to_i}s."
      clear_update(package, apk_file)
      return
    end
    case $1
    when 'INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES'
      puts 'Found package signed with different certificate.  Uninstalling it and retrying install.'
    when 'INSTALL_FAILED_INVALID_URI', %r{failed to copy '(?:.*)' to '(.*)/RubotoTestApp-debug.apk': Read-only file system}
      push_dir = $1 || '/data/local/tmp'
      puts "Maybe wrong write permissions for APK push directory #{push_dir.inspect}.  Changing permissions."
      puts `adb shell ls -l #{File.dirname(push_dir)}`
      puts `adb shell chmod a+rwx #{push_dir}`
      puts `adb shell ls -l #{File.dirname(push_dir)}`
    when 'INSTALL_FAILED_ALREADY_EXISTS'
      puts 'Package allready exists.'
      if replace_apk
        puts 'Uninstalling package.'
      else
        replace_apk = true
        next
      end
    else
      puts "'adb install' returned an unknown error: (#$?) #{$1 ? "[#$1}]" : output}."
      puts "Uninstalling #{package} and retrying install."
    end

    uninstall_apk(package, apk_file)
    replace_apk = false
  end

  clear_update(package, apk_file)
  raise "Install failed (#{$?}) #{$1 ? "[#$1}]" : output}"
end

def uninstall_apk(package_name, apk_file)
  return if package_installed?(package_name, apk_file).nil?
  puts "Uninstalling package #{package_name}"
  system "adb uninstall #{package_name}"
  if $? != 0 && package_installed?(package, apk_file)
    puts "Uninstall failed exit code #{$?}"
    exit $?
  end
end

def make_device_path(package, path)
  puts `adb shell #{"run-as #{package}" if sdk_level >= 23} mkdir -p #{path}`
  device_path_exists?(path)
end

def update_scripts(package)
  scripts_path = scripts_path(package)
  if !device_path_exists?(scripts_path) && !make_device_path(package, scripts_path)
    raise "Unable to create device scripts dir: #{scripts_path}"
  end
  mark_time = File.exists?(UPDATE_MARKER_FILE) ? File.read(UPDATE_MARKER_FILE) : '1970-01-01T00:00:00'
  last_update = Time.parse(mark_time)
  Dir.chdir('src') do
    source_files = Dir['**/*.rb']
    changed_files = source_files.select { |f| !File.directory?(f) && File.mtime(f) >= last_update && f !~ /~$/ }
    unless changed_files.empty?
      puts 'Pushing files to apk public file area:'
      changed_files.each do |script_file|
        print "#{script_file}: "; $stdout.flush
        system "adb push #{script_file} #{scripts_path}/#{script_file}"
      end
      mark_update
      return changed_files
    end
  end
  nil
end
