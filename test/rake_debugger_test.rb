require_relative 'test_helper'

# debugger gems are only compatible with JRuby
if RUBY_ENGINE == 'jruby'

  class RakeDebuggerTest < Minitest::Test

    DEBUGGER_GEMS = [
      [ 'columnize',       '~> 0.9.0' ],
      [ 'linecache',       '~> 1.3.1' ],
      [ 'ruby-debug-base', '~> 0.10.6' ],
      [ 'ruby-debug',      '~> 0.10.6' ],
    ]

    def setup
      generate_app
    end

    def teardown
      cleanup_app
    end

    def test_debugger_bundle
      Dir.chdir APP_DIR do
        FileUtils.rm 'libs/bundle.jar' if File.exists?('libs/bundle.jar')
        FileUtils.rm 'Gemfile.apk'     if File.exists?('Gemfile.apk')
        system 'rake debugger:bundle'
        assert_equal 0, $?
          assert File.exists?('libs/bundle.jar')
        assert File.exists?('Gemfile.apk')
        gemfile_gems = gems_in_gemfile 'Gemfile.apk'
        assert DEBUGGER_GEMS.all? { |gem| gemfile_gems.include? gem }
      end
    end

    def test_debugger_unbundle
      Dir.chdir APP_DIR do
        system 'rake debugger:unbundle'
        assert_equal 0, $?
          assert !File.exists?('libs/bundle.jar')
        assert File.exists?('Gemfile.apk')
        gemfile_gems = gems_in_gemfile 'Gemfile.apk'
        assert DEBUGGER_GEMS.none? { |gem| gemfile_gems.include? gem }
      end
    end

    def test_debugger_run
      # system 'rake debugger:run'
    end

    def gems_in_gemfile gem_file = GEM_FILE
      return [] unless File.exists? gem_file
      File.readlines( gem_file ).collect do |line|
        [$1,$2] if line =~ /^\s*gem\s*['"](.+)['"]\s*,\s*['"](.+)['"]/
      end.compact
    end

  end

end

