# frozen_string_literal: true

require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'

# Runs lib/jruby10_legacy on the JVM: a class using java.lang.invoke,
# VarHandles and newer JDK APIs must behave the same after it has been moved
# onto the org.ruboto.invoke stand-in.  Needs a JDK (17+) but no Android SDK.
class LegacyAndroidPatcherTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  LEGACY = "#{ROOT}/lib/jruby10_legacy"
  EXPECTED_OUTPUT = 'x1,y2,5,true,false,a,0,5,true,1,513,Integer,hello,2'

  SAMPLE = "#{__dir__}/legacy_android_patcher/Sample.java"

  def setup
    skip 'needs javac and java' unless system('javac -version', %i[out err] => File::NULL)
    # The patcher uses the ASM bundled in jruby-core.
    @asm = jruby_core_jar
    skip 'needs the jruby-jars gem (gem install jruby-jars)' unless @asm
    @dir = Dir.mktmpdir('legacy_patcher')
    run!("javac -d #{@dir}/classes #{SAMPLE}")
  end

  def teardown
    FileUtils.rm_rf @dir if @dir
  end

  def test_patched_class_behaves_the_same_on_the_stand_in
    original = run!("java -cp #{@dir}/classes Sample")
    patch!
    patched = run!("java -cp #{@dir}/classes Sample")

    assert_equal [EXPECTED_OUTPUT, 'java.lang.invoke'], summary(original)
    assert_equal [EXPECTED_OUTPUT, 'org.ruboto.invoke'], summary(patched)
  end

  def test_no_java_lang_invoke_references_remain_outside_invokedynamic
    patch!
    disassembly = run!("javap -c -p -cp #{@dir}/classes Sample")
    offending = disassembly.lines.grep(%r{java/lang/invoke|java/lang/ClassValue|BigInteger\.TWO|InputStream\.readAllBytes})
    offending = offending.reject { |l| l.include?('InvokeDynamic') }

    assert_empty offending
  end

  private

  # Compiles the stand-in into the class tree and runs the patcher over it.
  def patch!
    runtime = Dir["#{LEGACY}/runtime/**/*.java"].join(' ')
    run!("javac --release 17 -nowarn -d #{@dir}/classes #{runtime}")
    run!("javac -cp #{@asm} -d #{@dir}/tool #{LEGACY}/LegacyAndroidPatcher.java")
    report = run!("java -cp #{@asm}#{File::PATH_SEPARATOR}#{@dir}/tool LegacyAndroidPatcher #{@dir}/classes")
    raise "Unexpected patcher output: #{report}" unless report.include?('Patched')
  end

  # The program's result line and the package its MethodHandle came from.
  def summary(output)
    result, handle_class = output.lines.map(&:chomp)
    [result, handle_class[/\A\w+\.\w+\.invoke/]]
  end

  def jruby_core_jar
    require 'jruby-jars'
    JRubyJars.core_jar_path
  rescue LoadError
    nil
  end

  def run!(command)
    output = `#{command} 2>&1`

    assert_predicate $?, :success?, "#{command} failed:\n#{output}"
    output
  end
end
