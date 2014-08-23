lib = File.dirname(File.dirname(__FILE__)) + '/lib'
$:.unshift(lib) unless $:.include?(lib)
require 'test/unit'
require 'rubygems'
require 'fileutils'
require 'yaml'
require 'ruboto/sdk_versions'
require 'ruboto/sdk_locations'
require 'ruboto/util/update'

module RubotoTest
  include Ruboto::SdkVersions
  include Ruboto::SdkLocations
  include Ruboto::Util::Update

  PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
  $LOAD_PATH << PROJECT_DIR

  GEM_PATH = File.join PROJECT_DIR, 'tmp', 'gems'
  FileUtils.mkdir_p GEM_PATH
  ENV['GEM_HOME'] = GEM_PATH
  ENV['GEM_PATH'] = GEM_PATH
  ENV['PATH'] = "#{GEM_PATH}/bin:#{ENV['PATH']}"
  Gem.paths = GEM_PATH
  Gem.refresh
  `gem query -i -n bundler`
  system 'gem install bundler --no-ri --no-rdoc' unless $? == 0
  `bundle check`
  system 'bundle --system' unless $? == 0
  lib_path = File.expand_path('lib', File.dirname(File.dirname(__FILE__)))
  $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
  require 'ruboto'
  require 'ruboto/version'

  PACKAGE = 'org.ruboto.test_app'
  APP_NAME = 'RubotoTestApp'
  TMP_DIR = File.join PROJECT_DIR, 'tmp'
  APP_DIR = File.join TMP_DIR, APP_NAME

  # FIXME(uwe):  Remove special case when Android L has been released.
  if (ENV['ANDROID_TARGET'] && ENV['ANDROID_TARGET'] =~ /(?:android-)?L/)
    ANDROID_TARGET = 'L'
  else
    ANDROID_TARGET = (ENV['ANDROID_TARGET'] && ENV['ANDROID_TARGET'].slice(/\d+/).to_i) || MINIMUM_SUPPORTED_SDK_LEVEL
  end
  # EMXIF

  def self.version_from_device
    puts 'Reading OS version from device/emulator'
    system 'adb wait-for-device'
    IO.popen('adb bugreport').each_line do |line|
      if line =~ /sdk-eng (.*?) .*? .*? test-keys/
        version = $1
        api_level = VERSION_TO_API_LEVEL[version]
        raise "Unknown version: #{version}" if api_level.nil?
        return "android-#{api_level}"
      end
      if line =~ /\[ro\.build\.version\.sdk\]: \[(\d+)\]/
        return $1
      end
    end
    raise 'Unable to read device/emulator apilevel'
  end

  def uninstall_jruby_jars_gem
    uninstall_ruboto_gem
    uninstall_gem('jruby-jars')
  end

  def uninstall_ruboto_gem
    uninstall_gem('ruboto')
  end

  def uninstall_gem(name)
    `gem query --no-installed -n #{name}`
    system "gem uninstall -x --all #{name}" if $? != 0
    assert_equal 0, $?, "uninstall of #{name} failed with return code #$?"
  end

  def install_ruboto_gem(version)
    version_requirement = "-v #{version}"
    `gem query -i -n ^ruboto$ #{version_requirement}`
    system "gem install ruboto #{version_requirement} --no-ri --no-rdoc" unless $? == 0
    raise "install of ruboto #{version} failed with return code #$?" unless $? == 0
  end

  puts RUBY_DESCRIPTION

  ANDROID_OS = (ENV['ANDROID_OS'] || version_from_device).slice(/\d+/).to_i

  # FIXME(uwe): Remove when Android L has been released
  ANDROID_OS = 21 if ANDROID_OS == 0
  # EMXIF

  puts "ANDROID_OS: #{ANDROID_OS}"
  puts "ANDROID_TARGET: #{ANDROID_TARGET}"

  RUBOTO_CMD = "ruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto"

  puts "ANDROID_HOME: #{ANDROID_HOME}"
  puts "ANDROID_SDK_TOOLS_REVISION: #{ANDROID_TOOLS_REVISION}"

  RUBOTO_PLATFORM = ENV['RUBOTO_PLATFORM'] || 'CURRENT'
  puts "RUBOTO_PLATFORM: #{RUBOTO_PLATFORM}"

  if RUBOTO_PLATFORM == 'CURRENT'
    JRUBY_JARS_VERSION = Gem::Version.new('1.7.12')
  elsif ENV['JRUBY_JARS_VERSION']
    JRUBY_JARS_VERSION = Gem::Version.new(ENV['JRUBY_JARS_VERSION'])
  else
    # FIXME(uwe):  Simplify when we stop supporting rubygems < 1.8.0
    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.8.0')
      gem_spec = Gem::Specification.find_by_path 'jruby-jars'
    else
      gem_spec = Gem.searcher.find('jruby-jars')
    end
    # EMXIF

    raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
    JRUBY_JARS_VERSION = gem_spec.version
  end

  puts "JRUBY_JARS_VERSION: #{JRUBY_JARS_VERSION}"
  ENV['JRUBY_JARS_VERSION'] = JRUBY_JARS_VERSION.to_s
  ENV['LOCAL_GEM_DIR'] = Dir.getwd
end

class Test::Unit::TestCase
  include RubotoTest
  extend RubotoTest

  alias old_run run

  def run(*args, &block)
    mark_test_start("#{self.class.name}\##{respond_to?(:method_name) ? method_name : __name__}")
    old_run(*args, &block)
    mark_test_end("#{self.class.name}\##{respond_to?(:method_name) ? method_name : __name__}")
  end

  def mark_test_start(test_name)
    @start_time = Time.now
    log
    log '=' * 80
    log "Starting test #{test_name} at #{@start_time.strftime('%Y-%m-%d %H:%M:%S')}:"
    log
  end

  def mark_test_end(test_name)
    log
    duration = (Time.now - @start_time).to_i
    log "Ended test #{test_name}: #{passed? ? 'PASSED' : 'FAILED'} after #{duration / 60}:#{'%02d' % (duration % 60)}"
    log '=' * 80
    log
  end

  def log(message = '')
    puts message
    `adb shell log -t 'RUBOTO TEST' '#{message}'`
  end

  def generate_app(options = {})
    bundle = options.delete(:bundle)
    example = options.delete(:example) || false

    # FIXME(uwe): Remove exclusion feature
    excluded_stdlibs = options.delete(:excluded_stdlibs)
    # EMXIF

    heap_alloc = options.delete(:heap_alloc)
    included_stdlibs = options.delete(:included_stdlibs)
    package = options.delete(:package) || PACKAGE
    standalone = options.delete(:standalone) || !!included_stdlibs || !!excluded_stdlibs || ENV['RUBOTO_PLATFORM'] == 'STANDALONE'
    update = options.delete(:update) || false
    ruby_version = options.delete(:ruby_version) || (JRUBY_JARS_VERSION.to_s[0..0] == '9' ? 2.1 : 1.9)

    raise "Unknown options: #{options.inspect}" unless options.empty?
    raise 'Inclusion/exclusion of libs requires standalone mode.' if (included_stdlibs || excluded_stdlibs) && !standalone

    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR

    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    template_dir = "#{APP_DIR}_template_#{$$}"
    template_dir << "_package_#{package}" if package != PACKAGE
    template_dir << "_heap_alloc_#{heap_alloc}" if heap_alloc
    #    template_dir << "_ruby_version_#{ruby_version.to_s.gsub('.', '_')}" if ruby_version
    template_dir << "_example_#{example}" if example
    template_dir << "_bundle_#{[*bundle].join('_')}" if bundle
    template_dir << '_updated' if update
    template_dir << '_standalone' if standalone
    template_dir << "_without_#{excluded_stdlibs.map { |ed| ed.gsub(/[.\/]/, '_') }.join('_')}" if excluded_stdlibs
    template_dir << "_with_#{included_stdlibs.map { |ed| ed.gsub(/[.\/]/, '_') }.join('_')}" if included_stdlibs
    if File.exists?(template_dir)
      puts "Copying app from template #{template_dir}"
      FileUtils.cp_r template_dir, APP_DIR, :preserve => true
    else
      if example
        Dir.chdir TMP_DIR do
          system "tar xzf #{PROJECT_DIR}/examples/#{APP_NAME}_#{example}.tgz"
        end
        Dir.chdir APP_DIR do
          File.open('local.properties', 'w') { |f| f.puts "sdk.dir=#{ANDROID_HOME}" }
          File.open('test/local.properties', 'w') { |f| f.puts "sdk.dir=#{ANDROID_HOME}" }
          if standalone
            if included_stdlibs || excluded_stdlibs || heap_alloc || ruby_version
              write_ruboto_yml(included_stdlibs, excluded_stdlibs, heap_alloc, ruby_version)
            end
            FileUtils.touch 'libs/jruby-core-x.x.x.jar'
            FileUtils.touch 'libs/jruby-stdlib-x.x.x.jar'
            install_jruby_jars_gem
          else
            FileUtils.rm(Dir['libs/{jruby-*.jar,dx.jar}'])
          end
        end
      else
        if standalone
          install_jruby_jars_gem
        else
          uninstall_jruby_jars_gem
        end
        puts "Generating app #{APP_DIR}"
        system "#{RUBOTO_CMD} gen app --package #{package} --path #{APP_DIR} --name #{APP_NAME} --target android-#{ANDROID_TARGET}"
        if $? != 0
          FileUtils.rm_rf APP_DIR
          raise "gen app failed with return code #$?"
        end
        Dir.chdir APP_DIR do
          write_gemfile(bundle) if bundle
          if included_stdlibs || excluded_stdlibs || heap_alloc || ruby_version
            sleep 1
            write_ruboto_yml(included_stdlibs, excluded_stdlibs, heap_alloc, ruby_version)
            system 'rake build_xml jruby_adapter'
          end
          if standalone
            system "#{RUBOTO_CMD} gen jruby #{JRUBY_JARS_VERSION}"
            raise "update jruby failed with return code #$?" if $? != 0
          end
        end
      end

      Dir.chdir APP_DIR do
        File.write('AndroidManifest.xml',
            File.read('AndroidManifest.xml').sub(%r{</manifest>},
                "    <uses-permission android:name='android.permission.INTERNET'/>\n</manifest>"))
        File.write('res/layout/dummy_layout.xml', <<-EOF)
<?xml version="1.0" encoding="utf-8"?>
<TextView xmlns:android="http://schemas.android.com/apk/res/android"
  android:id="@+id/my_text"
  android:layout_width="wrap_content" android:layout_height="wrap_content"
  android:text="This is a dummy layout to generate layout and id constants." />
        EOF
        if update
          update_app
        end
        if update || !example
          system 'rake debug' # Ensure dx heap space is sufficient.
          assert_equal 0, $?
          Dir.chdir 'test' do
            system '#{ANT_CMD} instrument' # This will also build the main project.
            assert_equal 0, $?
          end
        end
      end
      puts "Storing app as template #{template_dir}"
      FileUtils.cp_r APP_DIR, template_dir, :preserve => true
    end
  end

  def update_app
    system "#{RUBOTO_CMD} update app"
    assert_equal 0, $?, "update app failed with return code #$?"
  end

  def cleanup_app
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def run_app_tests
    check_platform_installation
    test_completed = false
    Thread.start do
      4.times do
        sleep 600
        break if test_completed
        puts '...'
      end
    end
    Dir.chdir APP_DIR do
      system 'rake test:quick'
      assert_equal 0, $?, "tests failed with return code #$?"
    end
    test_completed = true
  end

  def check_platform_installation
    if RUBOTO_PLATFORM == 'STANDALONE'
      system 'rake platform:uninstall'
    elsif RUBOTO_PLATFORM == 'CURRENT'
      system 'rake platform:current'
    elsif RUBOTO_PLATFORM == 'FROM_GEM'
      system 'rake platform:install'
    else
      fail "Unknown Ruboto platform: #{RUBOTO_PLATFORM.inspect}"
    end
    if $? != 0
      FileUtils.rm_rf 'tmp/RubotoCore'
      fail 'Error (un)installing RubotoCore'
    end
  end

  def write_ruboto_yml(included_stdlibs, excluded_stdlibs, heap_alloc, ruby_version)
    yml = YAML.dump({'included_stdlibs' => included_stdlibs,
        'excluded_stdlibs' => excluded_stdlibs,
        # 'ruby_version' => ruby_version,
        'heap_alloc' => heap_alloc,
    })
    puts "Adding ruboto.yml:\n#{yml}"
    File.open('ruboto.yml', 'w') { |f| f << yml }
  end

  def write_gemfile(bundle)
    gems = [*bundle]
    puts "Adding Gemfile.apk: #{gems.join(' ')}"
    File.open('Gemfile.apk', 'w') do |f|
      f << "source 'http://rubygems.org/'\n\n"
      gems.each { |g| f << "gem #{[*g].map { |gp| "'#{gp}'" }.join(', ')}\n" }
    end
  end

end
