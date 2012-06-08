require File.expand_path("test_helper", File.dirname(__FILE__))

module AppTestMethods
  include RubotoTest

  def test_activity_tests
    assert_code 'YamlLoads', "with_large_stack{require 'yaml'}"
    assert_code 'ReadSourceFile', 'File.read(__FILE__)'
    assert_code 'DirListsFilesInApk', 'Dir["#{File.dirname(__FILE__)}/*"].each{|f| raise "File #{f.inspect} not found" unless File.exists?(f)}'
    assert_code 'RepeatRubotoImport', 'ruboto_import :TextView ; ruboto_import :TextView'

    Dir[File.expand_path('activity/*_test.rb', File.dirname(__FILE__))].each do |test_src|
      snake_name = test_src.chomp('_test.rb')
      activity_name = File.basename(snake_name).split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join
      Dir.chdir APP_DIR do
        system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}"
        FileUtils.cp "#{snake_name}.rb", "src/"
        FileUtils.cp test_src, "test/src/"
      end
    end
    run_app_tests
  end

  private

  def assert_code(activity_name, code)
    snake_name = activity_name.scan(/[A-Z]+[a-z]+/).map { |s| s.downcase }.join('_')
    filename = "src/#{snake_name}_activity.rb"
    Dir.chdir APP_DIR do
      system "#{RUBOTO_CMD} gen class Activity --name #{activity_name}Activity"
      s = File.read(filename)
      s.gsub!(/(require 'ruboto')/, "\\1\n#{code}")
      File.open(filename, 'w') { |f| f << s }
    end
  end

end
