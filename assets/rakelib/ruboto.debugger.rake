
namespace :debugger do

  GEM_SOURCE = "'https://rubygems.org'"
  DEBUGGER_GEMS = [
    [ 'columnize',       '~> 0.9.0' ],
    [ 'linecache',       '~> 1.3.1' ],
    [ 'ruby-debug-base', '~> 0.10.6' ],
    [ 'ruby-debug',      '~> 0.10.6' ],
  ]

  # TODO: (gf) use development or custom 'debug' group ? - will have to be included by debug task, and excluded for release
  task :add_to_gemfile do
    add_debugger_to_gemfile
  end

  task :local_bundle do
    sh "bundle install --gemfile=#{GEM_FILE}"
  end

  desc 'Add debugging gems to Gemfile, Gemfile.apk, and update bundle.jar'
  task bundle: [ :add_to_gemfile, :local_bundle, '^bundle' ]

  task :remove_from_gemfile do
    remove_debugger_from_gemfile
  end

  desc 'Remove debugging gems from Gemfile and update bundle.jar'
  task unbundle: :remove_from_gemfile do
    if File.exists? BUNDLE_JAR
      puts "Removing #{BUNDLE_JAR}"
      FileUtils.rm_f BUNDLE_JAR
    end
    Rake::Task['^bundle'].invoke unless gems_in_gemfile.empty?
  end
  
  desc 'Connect debugger client to app, accepts rdebug arguments after "--"'
  task :run do
    sep = ARGV.index('--')
    args = sep ? ARGV[sep+1..-1] : []
    wait_for_valid_device
    system "adb forward tcp:8989 tcp:8989"
    system "adb forward tcp:8990 tcp:8990"
    system "adb forward --list"
    system "rdebug --client #{args.join ' '}"
  end

  def gems_in_gemfile gem_file = GEM_FILE
    return [] unless File.exists? gem_file
    File.readlines( gem_file ).collect do |line|
      [$1,$2] if line =~ /^\s*gem\s*['"](.+)['"]\s*,\s*['"](.+)['"]/
    end.compact
  end

  def add_debugger_to_gemfile gem_file = GEM_FILE
    debugger_gems = DEBUGGER_GEMS
    # get list of missing debugger gems
    if File.exists? gem_file
      puts "Checking #{gem_file}"
      File.readlines( gem_file ).each do |line|
        debugger_gems.reject! do |name,version|
          ( puts "Found gem #{name}" ; true ) if line =~ /^\s*gem\s*['"]#{name}['"]/
        end
      end
    end
    add_gems_to_gemfile debugger_gems, gem_file
  end

  def add_gems_to_gemfile gems, gem_file = GEM_FILE
    unless gems.empty?
      existing_file = File.exists? gem_file
      puts "#{existing_file ? 'Adding to' : 'Creating'} #{gem_file}"
      File.open( gem_file, 'a' ) do |file|
        file.puts "source #{GEM_SOURCE}" unless existing_file
        gems.each do |name,version|
          file.puts "gem '#{name}', '#{version}'"
          puts "Added gem #{name}"
        end
      end
    end
  end

  def remove_debugger_from_gemfile gem_file = GEM_FILE
    debugger_gems = DEBUGGER_GEMS
    if File.exists? gem_file
      puts "Checking #{gem_file}"
      old_content = File.readlines gem_file
      new_content = old_content.reject do |line|
        debugger_gems.detect do |name,version|
          ( puts "Remove gem #{name}" ; true ) if line =~ /^\s*gem\s*['"]#{name}['"]/
        end
      end
      if new_content != old_content
        puts "Saving file #{gem_file}"
        File.write gem_file, new_content.join
      else
        puts "No debugger gems found"
      end
    else
      puts "File #{gem_file} not found"
    end
  end

end
