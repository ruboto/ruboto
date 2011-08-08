require File.expand_path("test_helper", File.dirname(__FILE__))

module AppTestMethods
  include RubotoTest

  if ['android-7', 'android-8'].include? ANDROID_OS
    def test_nothing
      puts "Skipping instrumentation tests on #{ANDROID_OS} since they don't work."
    end
  else
    def test_activity_tests
      if not ON_JRUBY_JARS_1_5_6
        assert_code 'YamlLoads', "with_large_stack{require 'yaml'}"
      else
        puts "Skipping YAML tests on jruby-jars-1.5.6"
      end

      assert_code 'ReadSourceFile', "File.read(__FILE__)"

      Dir[File.expand_path('activity/*_test.rb', File.dirname(__FILE__))].each do |test_src|
        snake_name = test_src.chomp('_test.rb')
        activity_name = File.basename(snake_name).split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join
        Dir.chdir APP_DIR do
          system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}"
          FileUtils.cp "#{snake_name}.rb", "assets/scripts/"
          FileUtils.cp test_src, "test/assets/scripts/"
        end
      end
      run_app_tests
    end

    private

    def assert_code(activity_name, code)
      snake_name = activity_name.scan(/[A-Z]+[a-z]+/).map { |s| s.downcase }.join('_')
      filename = "assets/scripts/#{snake_name}_activity.rb"
      Dir.chdir APP_DIR do
        system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}Activity"
        s = File.read(filename)
        s.gsub!(/(require 'ruboto')/, "\\1\n#{code}")
        File.open(filename, 'w') { |f| f << s }
      end
    end

  end

end