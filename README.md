# Ruboto 2

Ruboto 2 is a redesign based on an [Android Studio](https://developer.android.com/studio/) workflow.
This means that the JRuby and Ruboto components will integrate into the standard gradle tooling used by
regular Android Studio projects.

## Starting a new Ruboto project

* Download and install [Android studio](https://developer.android.com/studio/).
* Choose "Create New Project" in the startup screen.
  * Choose "Phone and Tablet" and "No Activity" for the project template.
  * Choose "Java" for your language and "Minimum SDK" should be "API 27" or higher.
  * "Use legacy android.support libraries" ?  "No", for now.
* Add the these dependencies to your `app/build.gradle` file:
  ```groovy
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation 'com.linkedin.dexmaker:dexmaker:2.19.1'
    implementation 'me.qmx.jitescript:jitescript:0.4.1'
    implementation 'com.jakewharton.android.repackaged:dalvik-dx:7.1.0_r7'
  ```
* Add `rakelib/ruboto.rake`:
  ```ruby
  abort 'JRuby required' unless RUBY_ENGINE == 'jruby'

  require 'time'
  
  PROJECT_DIR = File.expand_path('..', __dir__)
  BUNDLE_JAR = File.expand_path 'app/libs/bundle.jar', PROJECT_DIR
  BUNDLE_PATH = File.join(PROJECT_DIR, 'app', 'build', 'bundle')
  GEM_FILE = File.expand_path 'app/Gemfile'
  GEM_LOCK_FILE = "#{GEM_FILE}.lock"
  RUBY_SOURCE_FILES = Dir[File.expand_path 'app/src/main/resources/**/*.rb']
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
    next unless File.exists? GEM_FILE
    puts "Generating #{BUNDLE_JAR}"
    require 'bundler'
    Dir.chdir('app') do
      if true
        # FIXME(uwe): Issue #547 https://github.com/ruboto/ruboto/issues/547
        # Bundler.settings[:platform] = Gem::Platform::DALVIK
        # sh "bundle install --gemfile #{GEM_FILE} --path=#{BUNDLE_PATH} --platform=dalvik#{sdk_level} --without development test"
        # sh "bundle package --path=#{BUNDLE_PATH} --all --all-platforms"
        sh "bundle install --gemfile #{GEM_FILE} --path=#{BUNDLE_PATH} --without development test"
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
        unless File.exists? rel_dir
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
  ```
* Add `app/gems.rb`
  ```ruby
  source 'https://rubygems.org/'

  gem 'activerecord', '~>5.2'
  gem 'activerecord-jdbc-adapter', '~>52.6'
  gem 'sqldroid', '~>1.0'
  ```

* Add `app/update_jruby_jar.sh`:
  ```shell
  #!/usr/bin/env bash
  set +e
  
  VERSION="9.2.9.0"
  # FULL_VERSION="${VERSION}"
  # FULL_VERSION="${VERSION}-SNAPSHOT" # Uncomment to use a local snapshot
  FULL_VERSION="${VERSION}-20190822.050313-17" # Uncomment to use a remote snapshot
  JAR_FILE="jruby-complete-${FULL_VERSION}.jar"
  M2_CACHED_JAR="$HOME/.m2/repository/org/jruby/jruby-complete/${FULL_VERSION}/${JAR_FILE}"
  DOWNLOAD_DIR="$HOME/Downloads"
  DOWNLOADED_JAR="${DOWNLOAD_DIR}/${JAR_FILE}"
  
  cd libs
  rm -f bcpkix-jdk15on-*.jar bcprov-jdk15on-*.jar bctls-jdk15on-*.jar cparse-jruby.jar generator.jar jline-*.jar jopenssl.jar jruby-complete-*.jar parser.jar psych.jar readline.jar snakeyaml-*.jar
  
  # Try from local repository
  if [[ ! -f "${M2_CACHED_JAR}" ]] ; then
    echo No "${M2_CACHED_JAR}" - Downloading.
    set +e
    mvn dependency:get -DremoteRepositories=http://repo1.maven.org/maven2/ \
                   -DgroupId=org.jruby -DartifactId=jruby-complete -Dversion=${FULL_VERSION}
    set -e
  fi
  
  if [[ -f "${M2_CACHED_JAR}" ]] ; then
    cp -a ${M2_CACHED_JAR} .
  else
    # Snapshot version
    if test -f "${DOWNLOADED_JAR}"; then
      echo "Found downloaded JAR"
    else
      echo No "${DOWNLOADED_JAR}" - Downloading.
      wget "https://oss.sonatype.org/content/repositories/snapshots/org/jruby/jruby-complete/${VERSION}-SNAPSHOT/${JAR_FILE}" -P "${DOWNLOAD_DIR}/"
    fi
    cp ${DOWNLOADED_JAR} .
  fi
  
  unzip -j ${JAR_FILE} '*.jar'
  
  # FIXME(uwe): Why do we delete these files?
  zip generator.jar -d json/ext/ByteListTranscoder.class
  zip generator.jar -d json/ext/OptionsReader.class
  zip generator.jar -d json/ext/Utils.class
  zip generator.jar -d json/ext/RuntimeInfo.class
  
  cd - >/dev/null
  
  cd src/main/java
  find * -type f | grep "org/jruby/" | sed -e 's/\.java//g' | sort > ../../../overridden_classes.txt
  cd - >/dev/null
  
  while read p; do
    unzip -Z1 libs/${JAR_FILE} | grep "$p\\.class" > classes.txt
    unzip -Z1 libs/${JAR_FILE} | egrep "$p(\\\$[^$]+)*\\.class" >> classes.txt
    if [[ -s classes.txt ]] ; then
      zip -d -@ libs/${JAR_FILE} <classes.txt
      if [[ ! "$?" == "0" ]] ; then
        zip -d libs/${JAR_FILE} "$p\\.class"
      fi
    fi
    rm classes.txt
  done < overridden_classes.txt
  
  rm overridden_classes.txt
  ```

* Make `app/update_jruby_jar.sh` executable:

      chmod u+x app/update_jruby_jar.sh

* Generate `jruby.jar`:

      cd app
      ./update_jruby_jar.sh

* What next?

## Adding Ruboto to an existing Android Studio project

HOWTO missing.  Pull requests welcome!

# Ruboto 1.x

Looking for Ruboto 1.x?  Switch to the `ruboto_1.x` branch.
