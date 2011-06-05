require 'test/unit'
require 'rubygems'

class Test::Unit::TestCase
  PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
  $LOAD_PATH << PROJECT_DIR

  gem_spec = Gem.searcher.find('jruby-jars')
  raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
  JRUBY_JARS_VERSION  = gem_spec.version
  ON_JRUBY_JARS_1_5_6 = JRUBY_JARS_VERSION == Gem::Version.new('1.5.6')

  PACKAGE        ='org.ruboto.test_app'
  APP_NAME       = 'RubotoTestApp'
  TMP_DIR        = File.join PROJECT_DIR, 'tmp'
  APP_DIR        = File.join TMP_DIR, APP_NAME
  ANDROID_TARGET = ENV['ANDROID_TARGET'] || 'android-8'
  RUBOTO_CMD     = "jruby -rubygems -I #{PROJECT_DIR}/lib #{PROJECT_DIR}/bin/ruboto"

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
    if not File.exists?(template_dir)
      puts "Generating app template #{template_dir}"
      system "#{RUBOTO_CMD} gen app --package #{PACKAGE} --path #{template_dir} --name #{APP_NAME} --min_sdk #{ANDROID_TARGET} #{'--with-psych' if with_psych}"
      raise "gen app failed with return code #$?" unless $? == 0
    end
    FileUtils.cp_r template_dir, APP_DIR
  end

end
