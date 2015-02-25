######################################
#
# Methods for package installation
#

APK_FILE_REGEXP = /^-rw-r--r--\s+(?:system|\d+\s+\d+)\s+(?:system|\d+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}|\w{3} \d{2}\s+(?:\d{4}|\d{2}:\d{2}))\s+(.*)$/
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
    return nil if $? == 0 && path_line.empty?
    break if $? == 0 && path_line =~ /^package:(.*)$/
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

def scripts_path(package)
  @sdcard_path ||= "/mnt/sdcard/Android/data/#{package}/files/scripts"
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
  path_output =`adb shell ls #{path}`
  path_output.chomp !~ /No such file or directory|opendir failed, Permission denied/
end

def wait_for_valid_device
  while `adb shell echo "ping"`.strip != 'ping'
    `adb kill-server`
    `adb devices`
    sleep 5
  end
end

def install_apk(package, apk_file)
  wait_for_valid_device

  failure_pattern = /^Failure \[(.*)\]/
  success_pattern = /^Success/
  case package_installed?(package, apk_file)
  when true
    puts "Package #{package} already installed."
    return
  when false
    puts "Package #{package} already installed, but of different size or timestamp.  Replacing package."
    sh "adb shell date -s #{Time.now.strftime '%Y%m%d.%H%M%S'}"
    output = nil
    install_retry_count = 0
    begin
      timeout 300 do
        output = `adb install -r "#{apk_file}" 2>&1`
      end
    rescue Timeout::Error
      puts "Installing package #{package} timed out."
      install_retry_count += 1
      if install_retry_count <= 3
        puts 'Retrying install...'
        retry
      end
      puts 'Trying one final time to install the package:'
      output = `adb install -r "#{apk_file}" 2>&1`
    end
    if $? == 0 && output !~ failure_pattern && output =~ success_pattern
      clear_update(package, apk_file)
      return
    end
    case $1
    when 'INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES'
      puts 'Found package signed with different certificate.  Uninstalling it and retrying install.'
    else
      puts "'adb install' returned an unknown error: (#$?) #{$1 ? "[#$1}]" : output}."
      puts "Uninstalling #{package} and retrying install."
    end
    uninstall_apk(package, apk_file)
  else
    # Package not installed.
    sh "adb shell date -s #{Time.now.strftime '%Y%m%d.%H%M%S'}"
  end
  puts "Installing package #{package}"
  output = nil
  install_retry_count = 0
  begin
    timeout 300 do
      output = `adb install "#{apk_file}" 2>&1`
    end
  rescue Timeout::Error
    puts "Installing package #{package} timed out."
    install_retry_count += 1
    if install_retry_count <= 3
      puts 'Retrying install...'
      retry
    end
    puts 'Trying one final time to install the package:'
    install_start = Time.now
    output = `adb install "#{apk_file}" 2>&1`
    puts "Install took #{(Time.now - install_start).to_i}s."
  end
  puts output
  raise "Install failed (#{$?}) #{$1 ? "[#$1}]" : output}" if $? != 0 || output =~ failure_pattern || output !~ success_pattern
  clear_update(package, apk_file)
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

def update_scripts(package)
  # FIXME(uwe): Simplify when we stop supporting Android 2.3
  if sdk_level < 15
    scripts_path(package).split('/').tap do |parts|
      parts.size.times do |i|
        path = parts[0..i].join('/')
        puts(`adb shell mkdir #{path}`) unless device_path_exists?(path)
      end
    end
  else
    puts(`adb shell mkdir -p #{scripts_path(package)}`) unless device_path_exists?(scripts_path(package))
  end
  # EMXIF

  raise "Unable to create device scripts dir: #{scripts_path(package)}" unless device_path_exists?(scripts_path(package))
  last_update = File.exists?(UPDATE_MARKER_FILE) ? Time.parse(File.read(UPDATE_MARKER_FILE)) : Time.parse('1970-01-01T00:00:00')
  Dir.chdir('src') do
    source_files = Dir['**/*.rb']
    changed_files = source_files.select { |f| !File.directory?(f) && File.mtime(f) >= last_update && f !~ /~$/ }
    unless changed_files.empty?
      puts 'Pushing files to apk public file area:'
      changed_files.each do |script_file|
        print "#{script_file}: "; $stdout.flush
        system "adb push #{script_file} #{scripts_path(package)}/#{script_file}"
      end
      mark_update
      return changed_files
    end
  end
  nil
end
