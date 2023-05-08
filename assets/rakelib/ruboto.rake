abort 'JRuby required' unless RUBY_ENGINE == 'jruby'

require 'time'

PROJECT_DIR = File.expand_path('..', __dir__)
BUNDLE_JAR = File.expand_path 'app/libs/bundle.jar', PROJECT_DIR
BUNDLE_PATH = File.join(PROJECT_DIR, 'app', 'build', 'bundle')
GEM_FILE, GEM_LOCK_FILE = [['gems.rb', 'gems.locked'],['Gemfile', "Gemfile.lock"]]
    .map{|gf, lf| [File.expand_path("app/#{gf}", PROJECT_DIR), File.expand_path("app/#{lf}", PROJECT_DIR)]}
    .find{|gf, lf| File.exists?(gf)}
abort "#{PROJECT_DIR}/app/gems.rb not found." unless GEM_FILE
RUBY_SOURCE_FILES = Dir[File.expand_path 'app/src/main/resources/**/*.rb', PROJECT_DIR]
RUBY_ACTIVITY_SOURCE_FILES = RUBY_SOURCE_FILES.select { |fn| fn =~ /_activity.rb$/ }
RUBOTO_ACTIVITY_FILE = "#{PROJECT_DIR}/app/src/main/java/org/ruboto/RubotoActivity.java"

task default: [:bundle, :ruboto_activity]

desc 'Generate RubotoActivity'
task ruboto_activity: RUBOTO_ACTIVITY_FILE
file RUBOTO_ACTIVITY_FILE => RUBY_ACTIVITY_SOURCE_FILES do |task|
  puts 'Generate RubotoActivity'
  original_source = File.read(RUBOTO_ACTIVITY_FILE)
  next unless original_source =~ %r{\A(.*Generated Methods.*?\*/\n*)(.*)\B}m
  intro, generated_methods = $1, $2.scan(/(?:\s*\n*)(^\s*?public.*?^  }\n)/m).flatten
  puts "generated_methods: #{generated_methods.size}"
  implemented_methods = task.prerequisites.map { |f| File.read(f).scan(/(?:^\s*def\s+)([^\s(]+)/) }.flatten.sort
  puts "implemented_methods: #{implemented_methods.size}"
  puts "implemented_methods: #{implemented_methods.inspect}"
  commented_methods = generated_methods.map do |gm|
    implemented_methods.
        any? { |im| gm.upcase.include?(" #{im.upcase.gsub('_', '')}(") } ?
        gm : "/*\n#{gm}*/\n"
  end
  puts "commented_methods: #{commented_methods.size}"
  new_source = "#{intro}#{commented_methods.join("\n")}\n}\n"
  if new_source != original_source
    puts "Regenerating #{File.basename RUBOTO_ACTIVITY_FILE} with active methods"
    File.open(RUBOTO_ACTIVITY_FILE, 'w') { |f| f << new_source }
  end
end

file GEM_FILE
file GEM_LOCK_FILE

desc 'Generate bundle jar from Gemfile'
task bundle: BUNDLE_JAR

file BUNDLE_JAR => [GEM_FILE, GEM_LOCK_FILE] do
  next unless File.exist? GEM_FILE
  puts "Generating #{BUNDLE_JAR}"
  require 'bundler'
  Dir.chdir('app') do
    if true
      Bundler.with_unbundled_env do
        ENV['BUNDLE_PATH'] = BUNDLE_PATH
        ENV['BUNDLE_WITHOUT'] = 'development,test'
        sh "bundle install"
      end
    else
      # ENV["DEBUG"] = "true"
      require 'bundler/vendored_thor'

      # Store original RubyGems/Bundler environment
      platforms = Gem.platforms
      ruby_engine = defined?(RUBY_ENGINE) && RUBY_ENGINE
      env_home = ENV['GEM_HOME']
      env_path = ENV['GEM_PATH']

      # Override RUBY_ENGINE (we can bundle from MRI for JRuby)
      Gem.platforms = [Gem::Platform::RUBY, Gem::Platform.new("universal-dalvik-#{sdk_level}"), Gem::Platform.new('universal-java')]
      Gem.paths = {'GEM_HOME' => BUNDLE_PATH, 'GEM_PATH' => BUNDLE_PATH}
      Gem.refresh
      old_verbose, $VERBOSE = $VERBOSE, nil
      begin
        Object.const_set('RUBY_ENGINE', 'jruby')
        Object.const_set('JRUBY_VERSION', '7.7.7') unless defined?(JRUBY_VERSION)
      ensure
        $VERBOSE = old_verbose
      end
      ENV['BUNDLE_GEMFILE'] = GEM_FILE
      ENV['BUNDLE_PATH'] = BUNDLE_PATH

      Bundler.ui = Bundler::UI::Shell.new
      # Bundler.bundle_path = Pathname.new BUNDLE_PATH
      # Bundler.settings.without = [:development, :test]
      definition = Bundler.definition
      definition.validate_ruby!
      Bundler::Installer.install(Bundler.root, definition)
      unless Dir["#{BUNDLE_PATH}/bundler/gems/"].empty?
        system("mkdir -p '#{BUNDLE_PATH}/gems'")
        system("mv #{BUNDLE_PATH}/bundler/gems/* #{BUNDLE_PATH}/gems/")
      end

      # Restore RUBY_ENGINE (limit the scope of this hack)
      old_verbose, $VERBOSE = $VERBOSE, nil
      begin
        Object.const_set('RUBY_ENGINE', ruby_engine)
      ensure
        $VERBOSE = old_verbose
      end
      Gem.platforms = platforms
      ENV['GEM_HOME'] = env_home
      ENV['GEM_PATH'] = env_path
    end
  end

  GEM_PATH_PATTERN = /^PATH\s*remote:\s*(.*)$\s*specs:\s*(.*)\s+\(.+\)$/
  File.read(GEM_LOCK_FILE).scan(GEM_PATH_PATTERN).each do |path, name|
    FileUtils.mkpath "#{BUNDLE_PATH}/gems"
    FileUtils.rm_rf "#{BUNDLE_PATH}/gems/#{name}"
    FileUtils.cp_r File.expand_path(path, File.dirname(GEM_FILE)),
        "#{BUNDLE_PATH}/gems"
  end

  gem_paths = Dir["#{BUNDLE_PATH}/jruby/*/gems"]
  raise "Gem path not found: #{"#{BUNDLE_PATH}/gems"}" if gem_paths.empty?
  raise "Found multiple gem paths: #{gem_paths}" if gem_paths.size > 1
  gem_path = gem_paths[0]
  puts "Found gems in #{gem_path}"

  Dir.chdir gem_path do
    Dir['jruby-openssl-*/lib'].each do |g|
      rel_dir = "#{g}/lib/ruby"
      unless File.exist? rel_dir
        puts "Relocating #{g} files to match standard load path."
        dirs = Dir["#{g}/*"]
        FileUtils.mkdir_p rel_dir
        dirs.each do |d|
          FileUtils.move d, rel_dir
        end
      end
    end
  end

  # Expand JARs
  Dir.chdir gem_path do
    Dir['*'].each do |gem_lib|
      Dir.chdir "#{gem_lib}/lib" do
        Dir['**/*.jar'].each do |jar|
          unless jar =~ /sqlite-jdbc/
            puts "Expanding #{gem_lib} #{jar} into #{BUNDLE_JAR}"
            `jar xf #{jar}`
            if ENV['STRIP_INVOKERS']
              invokers = Dir['**/*$INVOKER$*.class']
              if invokers.size > 0
                puts "Removing invokers(#{invokers.size})..."
                FileUtils.rm invokers
              end
              populators = Dir['**/*$POPULATOR.class']
              if populators.size > 0
                puts "Removing populators(#{populators.size})..."
                FileUtils.rm populators
              end
            end
          end
          if jar == 'arjdbc/jdbc/adapter_java.jar'
            jar_load_code = <<~END_CODE
              require 'jruby'
              Java::arjdbc.jdbc.AdapterJavaService.new.basicLoad(JRuby.runtime)
            END_CODE

            # TODO(uwe): Seems ARJDBC requires all these classes to be present...
            # classes = Dir['arjdbc/**/*']
            # dbs = /db2|derby|firebird|h2|hsqldb|informix|mimer|mssql|mysql|oracle|postgres|sybase/i
            # files = classes.grep(dbs)
            # FileUtils.rm_f(files)
            # ODOT

            # FIXME(uwe): Extract files with case sensitive names for ARJDBC 1.2.7-1.3.x
            puts `jar xf #{jar} arjdbc/postgresql/PostgreSQLRubyJdbcConnection.class arjdbc/mssql/MSSQLRubyJdbcConnection.class arjdbc/sqlite3/SQLite3RubyJdbcConnection.class`
            # EMXIF

          elsif jar =~ /shared\/jopenssl.jar$/
            jar_load_code = <<~END_CODE
              require 'jruby'
              puts 'Starting JRuby OpenSSL Service'
              public
              Java::JopensslService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ %r{json/ext/generator.jar$}
            jar_load_code = <<~END_CODE
              require 'jruby'
              puts 'Starting JSON Generator Service'
              public
              Java::json.ext.GeneratorService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ %r{json/ext/parser.jar$}
            jar_load_code = <<~END_CODE
              require 'jruby'
              puts 'Starting JSON Parser Service'
              public
              Java::json.ext.ParserService.new.basicLoad(JRuby.runtime)
            END_CODE
          elsif jar =~ %r{thread_safe/jruby_cache_backend.jar$}
            jar_load_code = <<~END_CODE
              require 'jruby'
              puts 'Starting threadsafe JRubyCacheBackend Service'
              public
              begin
                Java::thread_safe.JrubyCacheBackendService.new.basicLoad(JRuby.runtime)
              rescue Exception
                puts "Exception starting threadsafe JRubyCacheBackend Service"
                puts $!
                puts $!.backtrace.join("\n")
                raise
              end
            END_CODE
          elsif jar =~ %r{concurrent_ruby_ext.jar$}
            puts "Adding JRuby extension library initialization."
            jar_load_code = <<~END_CODE
              require 'jruby'
              require 'ruboto/exception'
              require 'ruboto/stack'
              public
              begin
                with_large_stack(size: 2048, name: 'Starting ConcurrentRubyExtService') do
                  Java::ConcurrentRubyExtService.new.basicLoad(JRuby.runtime)
                end
              rescue Exception => e
                e.print_backtrace "Exception starting ConcurrentRubyExtService"
                raise
              end
            END_CODE
          else
            jar_load_code = ''
          end
          puts "Writing dummy JAR file #{jar + '.rb'}"
          File.open(jar + '.rb', 'w') { |f| f << jar_load_code }
          if jar.end_with?('.jar')
            puts "Writing dummy JAR file #{jar.sub(/.jar$/, '.rb')}"
            File.open(jar.sub(/.jar$/, '.rb'), 'w') { |f| f << jar_load_code }
          end
          FileUtils.rm_f(jar)
        end

        # FIXME(uwe):  Issue # 705 https://github.com/ruboto/ruboto/issues/705
        # FIXME(uwe):  Use the files from the bundle instead of stdlib.
        if (stdlib_jar = Dir["#{PROJECT_DIR}/libs/jruby-stdlib-*.jar"].sort.last)
          stdlib_files = `jar tf #{stdlib_jar}`.lines.map(&:chomp)
          Dir['**/*'].each do |f|
            if stdlib_files.include? f
              puts "Removing duplicate file #{f} in gem #{gem_lib}."
              puts 'Already present in the Ruby Standard Library.'
              FileUtils.rm f
            end
          end
        end
        # EMXIF

      end
    end
  end

  # Remove duplicate files
  Dir.chdir gem_path do
    scanned_files = []
    source_files = RUBY_SOURCE_FILES.map { |f| f.gsub("#{PROJECT_DIR}/src/", '') }
    # FIXME(uwe):  The gems should be loaded in the loading order defined by the Gemfile(.lock)
    Dir['*/lib/**/*'].sort.each do |f|
      next if File.directory? f
      raise 'Malformed file name' unless f =~ %r{^(.*?)/lib/(.*)$}
      gem_name, lib_file = $1, $2
      if (existing_file = scanned_files.find { |sf| sf =~ %r{(.*?)/lib/#{lib_file}} })
        puts "Overwriting duplicate file #{lib_file} in gem #{$1} with file in #{gem_name}"
        FileUtils.rm existing_file
        scanned_files.delete existing_file
      elsif source_files.include? lib_file
        puts "Removing duplicate file #{lib_file} in gem #{gem_name}"
        puts "Already present in project source src/#{lib_file}"
        FileUtils.rm f
        next
      end
      scanned_files << f
    end
  end

  FileUtils.rm_f BUNDLE_JAR
  Dir["#{gem_path}/*"].each_with_index do |gem_dir, i|
    `jar #{i == 0 ? 'c' : 'u'}f "#{BUNDLE_JAR}" -C "#{gem_dir}/lib" .`
  end
  FileUtils.rm_rf BUNDLE_PATH
end
