require File.expand_path('test_helper', File.dirname(__FILE__))

module AppTestMethods
  include RubotoTest

  def test_activity_tests
    if ENV['ACTIVITY_TEST_PATTERN']
      Dir.chdir APP_DIR do
        FileUtils.rm 'src/ruboto_test_app_activity.rb'
        FileUtils.rm 'test/src/ruboto_test_app_activity_test.rb'
      end
    else
      assert_code 'Base64Loads', "require 'base64'"

      # FIXME(uwe):  We should try using YAML as well
      assert_code 'YamlLoads', "require 'yaml'"

      assert_code 'ReadSourceFile', 'File.read(__FILE__)'
      assert_code 'DirListsFilesInApk', 'Dir["#{File.dirname(__FILE__)}/*"].each{|f| raise "File #{f.inspect} not found" unless File.exists?(f)}'
      assert_code 'RepeatRubotoImportWidget', 'ruboto_import_widget :TextView ; ruboto_import_widget :TextView'
    end
    run_activity_tests('activity')
  end

  private

  def assert_code(activity_name, code)
    snake_name = activity_name.scan(/[A-Z]+[a-z0-9]+/).map { |s| s.downcase }.join('_')
    filename = "src/#{snake_name}_activity.rb"
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}Activity"
      s = File.read(filename)
      raise 'Code injection failed!' unless s.gsub!(/(require 'ruboto\/widget')/, "\\1\n#{code}")
      File.open(filename, 'w') { |f| f << s }
    end
  end

  def run_activity_tests(activity_dir)
    Dir[File.expand_path("#{activity_dir}/*", File.dirname(__FILE__))].each do |file|
      # FIXME(uwe):  Remove when we stop testing api level < 16
      # FIXME(uwe):  Remove when we release RubotoCore with SSL included
      next if file =~ /ssl/ && (ANDROID_OS < 16 ||
          RUBOTO_PLATFORM == 'CURRENT' || RUBOTO_PLATFORM == 'FROM_GEM')
      # EMXIF

      # FIXME(uwe):  Remove when we stop testing JRuby < 1.7.4.dev
      next if file =~ /dir_and_file/ && (RUBOTO_PLATFORM == 'CURRENT' || JRUBY_JARS_VERSION < Gem::Version.new('1.7.4.dev'))
      # EMXIF

      # FIXME(uwe):  Remove when we stop testing api level < 11
      next if file =~ /fragment/ && ANDROID_OS < 11
      # EMXIF

      if file =~ /_test.rb$/
        next unless file =~ /#{ENV['ACTIVITY_TEST_PATTERN']}/
        snake_name = file.chomp('_test.rb')

        activity_name = File.basename(snake_name).split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join
        Dir.chdir APP_DIR do
          system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}"
          FileUtils.cp "#{snake_name}.rb", 'src/'
          FileUtils.cp file, 'test/src/'
        end
      elsif !File.exists? "#{file.chomp('.rb')}'_test.rb'"
        Dir.chdir APP_DIR do
          FileUtils.cp file, "src/"
        end
      end
    end
    run_app_tests
  end

end
