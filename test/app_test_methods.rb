require File.expand_path("test_helper", File.dirname(__FILE__))

module AppTestMethods
  include RubotoTest

  def test_activity_tests
    assert_code 'YamlLoads', "with_large_stack{require 'yaml'}"
    assert_code 'ReadSourceFile', 'File.read(__FILE__)'
    assert_code 'DirListsFilesInApk', 'Dir["#{File.dirname(__FILE__)}/*"].each{|f| raise "File #{f.inspect} not found" unless File.exists?(f)}'
    assert_code 'RepeatRubotoImport', 'ruboto_import :TextView ; ruboto_import :TextView'
    run_activity_tests('activity')
  end

  def test_block_def_activity_tests
    run_activity_tests('block_def_activity')
  end

  def test_handle_activity_tests
    Dir.chdir APP_DIR do
      FileUtils.rm "src/ruboto_test_app_activity.rb"
      FileUtils.rm "test/src/ruboto_test_app_activity_test.rb"
    end
    run_activity_tests('handle_activity')
  end

  private

  def assert_code(activity_name, code)
    snake_name = activity_name.scan(/[A-Z]+[a-z]+/).map { |s| s.downcase }.join('_')
    filename   = "src/#{snake_name}_activity.rb"
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}Activity"
      s = File.read(filename)
      s.gsub!(/(require 'ruboto')/, "\\1\n#{code}")
      File.open(filename, 'w') { |f| f << s }
    end
  end

  def run_activity_tests(activity_dir)
    Dir[File.expand_path("#{activity_dir}/*_test.rb", File.dirname(__FILE__))].each do |test_src|
      snake_name    = test_src.chomp('_test.rb')
      next if snake_name =~ /subclass/ && (RUBOTO_PLATFORM == 'CURRENT' || JRUBY_JARS_VERSION < Gem::Version.new('1.7.0.preview2'))
      activity_name = File.basename(snake_name).split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join
      Dir.chdir APP_DIR do
        system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}"
        FileUtils.cp "#{snake_name}.rb", "src/"
        FileUtils.cp test_src, "test/src/"
      end
    end
    run_app_tests
  end

end
