require 'yaml'
require 'fileutils'
require 'rexml/document'

namespace :libs do
  desc 'take a fresh copy of the stdlib and rebuild it for use with this project'
  task :reconfigure_stdlib do
    require_relative 'stdlib_dependencies'
    reconfigure_jruby_stdlib
  end

  desc 'check the stdlib dependencies and store them in auto_dependencies.yml'
  task :check_dependencies do
    require_relative 'stdlib_dependencies'

    if File.exists? 'auto_dependencies.yml'
      old_dep = (YAML::load_file('auto_dependencies.yml') || {})
    end

    new_dep = find_dependencies
    if new_dep == old_dep
      puts "Dependencies haven't changed: #{new_dep.join(', ')}"
    else
      puts "New dependencies: #{new_dep.join(', ')}"
      File.open( "auto_dependencies.yml", 'w' ) do |out|
        YAML.dump( new_dep, out )
      end
    end
  end
end

def log_action(initial_text, final_text="Done.", &block)
  $stdout.sync = true

  print initial_text, "..."
  result = yield
  puts final_text
  
  result
end

############################################################################
#
# Support for reconfigure_jruby_stdlib
#

# - Moves ruby stdlib to the root of the jruby-stdlib jar
def reconfigure_jruby_stdlib
  abort "cannot find jruby library in libs" if Dir["libs/jruby*"].empty?

  require 'jruby-jars'

  log_action("Copying #{JRubyJars::stdlib_jar_path} to libs") { FileUtils.cp JRubyJars::stdlib_jar_path, "libs/jruby-stdlib-#{JRubyJars::VERSION}.jar" }
  StdlibDependencies.load('rakelib/stdlib.yml')

  Dir.chdir 'libs' do
    jruby_stdlib = Dir['jruby-stdlib-*.jar'][-1]
    log_action("Reformatting #{jruby_stdlib}") do
      FileUtils.mkdir_p 'tmp'
      Dir.chdir 'tmp' do
        FileUtils.mkdir_p 'old'
        FileUtils.mkdir_p 'new/jruby.home'
        Dir.chdir 'old' do
          `jar -xf ../../#{jruby_stdlib}`
          raise "Unpacking jruby-stdlib jar failed: #$?" unless $? == 0
        end
        FileUtils.move 'old/META-INF/jruby.home/lib', 'new/jruby.home/lib'
        FileUtils.rm_rf 'new/jruby.home/lib/ruby/gems'

        remove_unneeded_parts_of_stdlib
        cleanup_jars

        Dir.chdir 'new' do
          `jar -cf ../../#{jruby_stdlib} .`
          raise "Creating repackaged jruby-stdlib jar failed: #$?" unless $? == 0
        end
      end

      FileUtils.remove_dir 'tmp', true
    end
  end
end

def remove_unneeded_parts_of_stdlib
  if File.exists? '../../ruboto.yml'
    ruboto_config = (YAML::load_file('../../ruboto.yml') || {})
  else
    ruboto_config = {}
  end

  ruby_version = ruboto_config['ruby_version']
  included_stdlibs = ruboto_config['included_stdlibs']
  excluded_stdlibs = [*ruboto_config['excluded_stdlibs']].compact

  if included_stdlibs and included_stdlibs == "auto"
    if File.exists? '../../auto_dependencies.yml'
      included_stdlibs = YAML::load_file('../../auto_dependencies.yml')
    else
      puts "No auto_dependencies.yml file found. Use 'rake libs:check_dependencies' to create one."
      included_stdlibs = nil
    end
  end

  Dir.chdir 'new/jruby.home/lib/ruby' do
    #
    # Add ruby_version (e.g., 1.8, 1.9, 2.0) to ruboto.yml
    # to trim unused versions from stdlib
    #
    if ruby_version
      ruby_stdlib_versions = Dir['*'] - %w(gems shared)
      print "ruby version = #{ruby_version}..."
      ruby_stdlib_versions.each do |ld|
        unless ld == ruby_version.to_s
          print "removing #{ld}..."
          FileUtils.rm_rf ld
        end
      end
    end

    if included_stdlibs
      ruby_version ||= 1.9
      ruby_version = ruby_version.to_s

      # Require jruby and java
      included_stdlibs = (included_stdlibs + %w(java jruby)).uniq

      ruby_stdlib_versions = Dir['*'] - %w(gems)
      print 'excluded...'
      ruby_stdlib_versions.each do |ld|
        Dir.chdir ld do
          libs = Dir['*'].map { |d| d.sub /\.(rb|jar)$/, '' }.uniq
          libs.each do |d|
            next if included_stdlibs.include? d
            FileUtils.rm_rf d if File.exists? d
            file = "#{d}.rb"
            FileUtils.rm_rf file if File.exists? file
            jarfile = "#{d}.jar"
            FileUtils.rm_rf jarfile if File.exists? jarfile
            print "#{d} "
          end
        end
      end
    end

    if included_stdlibs.nil? and excluded_stdlibs.any?
      # Don't allow jruby and java to be removed
      excluded_stdlibs = excluded_stdlibs - %w(jruby java)

      ruby_stdlib_versions = Dir['*'] - %w(gems)
      ruby_stdlib_versions.each do |ld|
        excluded_stdlibs.each do |d|
          dir = "#{ld}/#{d}"
          FileUtils.rm_rf dir if File.exists? dir
          file = "#{dir}.rb"
          FileUtils.rm_rf file if File.exists? file
        end
      end
      print "excluded #{excluded_stdlibs.join(' ')}..."
    end
  end
end

def cleanup_jars
  Dir.chdir 'new' do
    Dir['**/*.jar'].each do |j|

      # FIXME(uwe):  Installing bcmail-jdk15-146.jar + bcprov-jdk15-146.jar fails due to
      # http://code.google.com/p/android/issues/detail?id=40409
      # This breaks ssl and https. Remove when we stop supporting JRuby <= 1.7.2
      if j =~ /bcmail|bcprov-jdk15-146/
        FileUtils.rm j
        next
      end
      # EMXIF

      # FIXME(uwe): Adding the jars triggers the "LinearAlloc exceeded capacity"
      # bug in Android 2.3.  Remove when we stop supporting android-10 and older
      abort "cannot find your AndroidManifest.xml to extract info from it" unless File.exists? '../../../AndroidManifest.xml'
      manifest = REXML::Document.new(File.read('../../../AndroidManifest.xml')).root
      min_sdk_version = manifest.elements['uses-sdk'].attributes['android:minSdkVersion'].to_i
      if min_sdk_version <= 10
        FileUtils.rm j
        next
      end
      # EMXIF

      # FIXME(uwe): These should be included but break the 64K method count limit
      if j =~ /bcpkix-jdk15on-1\.?47|bcprov-jdk15on-1\.?47|jopenssl|kryptcore|kryptproviderjdk/
        FileUtils.rm j
        next
      end
      # EMXIF

      print "#{File.basename(j).chomp('.jar')}..."
      system "jar xf #{j}"
      FileUtils.rm j
      if ENV['STRIP_INVOKERS']
        invokers = Dir['**/*$INVOKER$*.class']
        if invokers.size > 0
          print "Removing invokers(#{invokers.size})..."
          FileUtils.rm invokers
        end
        populators = Dir['**/*$POPULATOR.class']
        if populators.size > 0
          print "Removing populators(#{populators.size})..."
          FileUtils.rm populators
        end
      end

      if j =~ %r{json/ext/generator.jar$}
        jar_load_code = <<-END_CODE
          require 'jruby'
          puts 'Starting JSON Generator Service'
          public
          Java::json.ext.GeneratorService.new.basicLoad(JRuby.runtime)
        END_CODE
      elsif j =~ %r{json/ext/parser.jar$}
        jar_load_code = <<-END_CODE
          require 'jruby'
          puts 'Starting JSON Parser Service'
          public
          Java::json.ext.ParserService.new.basicLoad(JRuby.runtime)
        END_CODE
      else
        jar_load_code = ''
      end

      File.open("#{j}.rb", 'w') { |f| f << jar_load_code }
      File.open("#{j}.jar.rb", 'w') { |f| f << jar_load_code }
    end
  end
end

############################################################################
#
# Support for check_dependencies
#

def find_dependencies
  if File.exists? 'rakefile/ruboto.yml'
    ruboto_config = (YAML::load_file('rakefile/ruboto.yml') || {})
  else
    ruboto_config = {}
  end
  ruby_version = ruboto_config['ruby_version'] || "1.9"

  local = StdlibDependencies.collect("src").dependencies
  stdlib = StdlibDependencies.load('rakelib/stdlib.yml')[ruby_version]

  dependencies = local.values.flatten
  new_values = []
  check_values = local.values.flatten

  while check_values.any?
    check_values.each do |j|
      new_values += stdlib[j] if stdlib[j] 
    end

    check_values = new_values - dependencies
    dependencies = dependencies + new_values
    new_values = []
  end

  dependencies.map{|d| d.split("/")[0]}.uniq.sort
end

