require 'test/unit'
require 'rubygems'

module RubotoTest
  PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
  $LOAD_PATH << PROJECT_DIR

  gem_spec = Gem.searcher.find('jruby-jars')
  raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
  JRUBY_JARS_VERSION  = gem_spec.version
  ON_JRUBY_JARS_1_5_6 = JRUBY_JARS_VERSION == Gem::Version.new('1.5.6')

  PACKAGE        = 'org.ruboto.test_app'
  APP_NAME       = 'RubotoTestApp'
  TMP_DIR        = File.join PROJECT_DIR, 'tmp'
  APP_DIR        = File.join TMP_DIR, APP_NAME
  ANDROID_TARGET = ENV['ANDROID_TARGET'] || 'android-7'

  VERSION_TO_API_LEVEL = {
      '2.1' => 'android-7', '2.1-update1' => 'android-7', '2.2' => 'android-8',
      '2.3' => 'android-9', '2.3.1' => 'android-9', '2.3.2' => 'android-9',
      '2.3.3' => 'android-10', '2.3.4' => 'android-10',
      '3.0' => 'android-11', '3.1' => 'android-12', '3.2' => 'android-13'
  }
  
  def self.version_from_device
    puts "Reading OS version from device/emulator"
    system "adb wait-for-device"
    start = Time.now
    IO.popen('adb bugreport').each_line do |line|
      if line =~ /sdk-eng (.*?) .*? .*? test-keys/
        version = $1
        api_level = VERSION_TO_API_LEVEL[version]
        raise "Unknown version: #{version}" if api_level.nil?
        puts "Getting version from device/emulator took #{(Time.now - start).to_i}s"
        return api_level
      end
    end
    raise "Unable to read device/emulator apilevel"
  end

  ANDROID_OS = ENV['ANDROID_OS'] || version_from_device
  RUBOTO_CMD = "ruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto"

  puts "ANDROID_OS: #{ANDROID_OS}"
end

class Test::Unit::TestCase
  include RubotoTest
  alias old_run run

  def run(*args, &block)
    mark_test_start("#{self.class.name}\##{method_name}")
    old_run(*args, &block)
    mark_test_end("#{self.class.name}\##{method_name}")
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
    log "Ended test #{test_name}: #{passed? ? 'PASSED' : 'FAILED'} after #{(Time.now - @start_time).to_i}s"
    log '=' * 80
    log
  end

  def log(message = '')
    puts message
    system "adb shell log -t 'RUBOTO TEST' '#{message}'"
  end

  def generate_app(options = {})
    with_psych = options.delete(:with_psych) || false
    raise "Unknown options: #{options.inspect}" unless options.empty?
    Dir.mkdir TMP_DIR unless File.exists? TMP_DIR
    FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
    template_dir = "#{APP_DIR}_template_#{$$}#{'_with_psych' if with_psych}"
    if File.exists?(template_dir)
      puts "Copying app from template #{template_dir}"
      FileUtils.cp_r template_dir, APP_DIR
    else
      puts "Generating app #{APP_DIR}"
      system "#{RUBOTO_CMD} gen app --package #{PACKAGE} --path #{APP_DIR} --name #{APP_NAME} --min_sdk #{ANDROID_TARGET} #{'--with-psych' if with_psych}"
      if $? != 0
        FileUtils.rm_rf template_dir
        raise "gen app failed with return code #$?"
      end
      Dir.chdir APP_DIR do
        system 'rake debug'
        assert_equal 0, $?
      end
      puts "Storing app as template #{template_dir}"
      FileUtils.cp_r APP_DIR, template_dir
    end
  end

  def cleanup_app
    # FileUtils.rm_rf APP_DIR if File.exists? APP_DIR
  end

  def run_app_tests
    Dir.chdir "#{APP_DIR}/test" do
      system 'rake test:quick'
      assert_equal 0, $?, "tests failed with return code #$?"
    end
  end

end
