# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'

# Runs JRuby's Java interface support on the JVM the way Ruboto runs it on
# Android: jruby.interfaces.useProxy=true and the Android
# ClassDefiningJRubyClassLoader override, which refuses to define any class at
# runtime.  RubyProc and JavaInterfaceTemplate go through JRuby10AndroidPatcher
# first.  Needs a JDK and the jruby-jars gem, but no Android SDK.
class InterfaceProxyPatchTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  OVERRIDES = "#{ROOT}/lib/jruby10_overrides"
  ASM_JAR = "#{ROOT}/assets/libs/asm-9.7.1.jar"
  PATCHED_CLASSES = %w[org/jruby/RubyProc.class org/jruby/java/proxies/JavaInterfaceTemplate.class].freeze

  SCRIPT = <<~'RUBY'
    def check(label)
      puts "#{label}=#{yield.inspect}"
    rescue Exception => e
      puts "#{label}=#{e.class}: #{e.message.lines.first.to_s.strip}"
    end
    class Counter
      include java.lang.Runnable
      attr_reader :count
      def initialize; @count = 0; end
      def run; @count += 1; end
    end
    list = java.util.ArrayList.new([3, 1, 2])
    check('block') { r = []; list.forEach { |x| r << x }; r }
    check('block_return') { java.util.stream.IntStream.of(1, 2, 3).reduce(0) { |a, b| a + b } }
    check('block_thread') { r = nil; t = java.lang.Thread.new { r = :ran }; t.start; t.join; r }
    check('impl') { r = nil; java.lang.Runnable.impl { |name| r = name }.run; r }
    check('include') { c = Counter.new; t = java.lang.Thread.new(c); t.start; t.join; c.count }
    check('proc') { r = nil; t = java.lang.Thread.new(proc { r = :proc }); t.start; t.join; r }
  RUBY

  EXPECTED = ['block=[3, 1, 2]', 'block_return=6', 'block_thread=:ran', 'impl=:run', 'include=1', 'proc=:proc'].freeze

  def setup
    skip 'needs javac and java' unless system('javac -version', %i[out err] => File::NULL)
    @core, @stdlib = jruby_jars
    skip 'needs the jruby-jars gem (gem install jruby-jars)' unless @core
    @dir = Dir.mktmpdir('interface_proxy_patch')
    FileUtils.mkdir_p "#{@dir}/classes"
    Dir.chdir("#{@dir}/classes") { run!("jar xf #{@core} #{PATCHED_CLASSES.join(' ')}") }
    run!("javac -nowarn -cp #{@core} -d #{@dir}/classes " \
         "#{OVERRIDES}/ClassDefiningJRubyClassLoader.java #{OVERRIDES}/RubotoInterfaceAllocator.java")
    run!("javac -cp #{ASM_JAR} -d #{@dir}/tool #{OVERRIDES}/JRuby10AndroidPatcher.java")
  end

  def teardown
    FileUtils.rm_rf @dir if @dir
  end

  def test_interfaces_work_without_runtime_class_generation
    report = run!("java -cp #{ASM_JAR}#{File::PATH_SEPARATOR}#{@dir}/tool JRuby10AndroidPatcher #{@dir}/classes")

    assert_includes report, "Patched #{PATCHED_CLASSES.size} classes"
    assert_equal EXPECTED, run_script.lines.map(&:chomp).grep(/=/)
  end

  private

  def run_script
    script = "#{@dir}/script.rb"
    File.write(script, SCRIPT)
    class_path = ["#{@dir}/classes", @core, @stdlib].join(File::PATH_SEPARATOR)
    run!('java -Djruby.interfaces.useProxy=true -Djruby.compile.mode=OFF -Djruby.native.enabled=false ' \
         "-cp #{class_path} org.jruby.Main #{script}")
  end

  def jruby_jars
    require 'jruby-jars'
    [JRubyJars.core_jar_path, JRubyJars.stdlib_jar_path]
  rescue LoadError
    nil
  end

  def run!(command)
    output = `#{command} 2>&1`

    assert_predicate $?, :success?, "#{command} failed:\n#{output}"
    output
  end
end
