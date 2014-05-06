require 'fileutils'

def log_action(initial_text, final_text='Done.', &block)
  $stdout.sync = true

  print initial_text, '...'
  result = yield
  puts final_text

  result
end

namespace :libs do
  desc 'rebuild the stdlib dependencies file (ruboto.stdlib.yml)'
  task :generate_stdlib_dependencies do
    require 'jruby-jars'

    require_relative '../assets/rakelib/stdlib_dependencies'

    log_action('Creating temporary directory') { FileUtils.mkdir_p 'tmp_stdlib' }
    Dir.chdir 'tmp_stdlib' do
      log_action('Unpacking stdlib') { `jar -xf #{JRubyJars::stdlib_jar_path}` }

      # Include ruboto dependencies
      FileUtils.cp_r '../assets/src/ruboto', 'META-INF/jruby.home/lib/ruby/shared'

      Dir.chdir 'META-INF/jruby.home/lib/ruby' do
        FileUtils.rm_rf 'gems'
        log_action('Generating dependencies') { StdlibDependencies.generate }
      end
    end

    log_action('Removing temporary directory') { FileUtils.remove_dir 'tmp_stdlib', true }
    log_action('Writing assets/rakelib/ruboto.stdlib.yml') { StdlibDependencies.dump('assets/rakelib/ruboto.stdlib.yml') }
  end
end

