require File.expand_path("test_helper", File.dirname(__FILE__))

module AppTest
  include RubotoTest

  if ['android-7', 'android-8'].include? ANDROID_OS
    def test_nothing
      puts "Skipping instrumentation tests on #{ANDROID_OS} since they don't work."
    end
  else
    def test_that_tests_work_on_new_project
      run_app_tests
    end

    if not ON_JRUBY_JARS_1_5_6
      def test_that_yaml_loads
        assert_code "with_large_stack{require 'yaml'}"
      end
    else
      puts "Skipping YAML tests on jruby-jars-1.5.6"
    end

    def test_file_read_source_file
      assert_code "File.read(__FILE__)"
    end

    Dir.chdir File.expand_path('activity', File.dirname(__FILE__)) do
      Dir['*_test.rb'].each do |test|
        class_eval %Q{
        def test_#{test.chomp('_test.rb')}
          filename      = "#{APP_DIR}/assets/scripts/ruboto_test_app_activity.rb"
          test_filename = "#{APP_DIR}/test/assets/scripts/ruboto_test_app_activity_test.rb"
          File.open(filename, 'w') { |f| f << File.read('#{PROJECT_DIR}/test/activity/#{test.gsub('_test', '')}') }
          File.open(test_filename, 'w') { |f| f << File.read('#{PROJECT_DIR}/test/activity/#{test}') }
          run_app_tests
        end
      }
        puts "Creating test from file #{PROJECT_DIR}/test/activity/#{test}"
      end
    end

    private

    def assert_code(code)
      filename = "#{APP_DIR}/assets/scripts/ruboto_test_app_activity.rb"
      s        = File.read(filename)
      s.gsub!(/(require 'ruboto')/, "\\1\n#{code}")
      File.open(filename, 'w') { |f| f << s }
      run_app_tests
    end

    def run_app_tests
      Dir.chdir "#{APP_DIR}/test" do
        system 'rake test:quick'
        assert_equal 0, $?, "tests failed with return code #$?"
      end
    end

  end

end
