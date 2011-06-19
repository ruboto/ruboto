require File.expand_path("test_helper", File.dirname(__FILE__))

module AppTest
  include RubotoTest
  
  def test_that_tests_work_on_new_project
    run_app_tests
  end

  if not ON_JRUBY_JARS_1_5_6
    def test_that_yaml_loads
      assert_code <<CODE
class Object
  def with_large_stack(stack_size_kb = 128, &block)
    result = nil
    t = Thread.with_large_stack(&proc{result = block.call})
    t.join
    result
  end
end

class Thread
  def self.with_large_stack(stack_size_kb = 128, &block)
    t = java.lang.Thread.new(nil, block, "block with large stack", stack_size_kb * 1024)
    t.start
    t
  end
end
with_large_stack{require 'yaml'}
CODE
    end
  else
    puts "Skipping YAML tests on jruby-jars-1.5.6"
  end

  def test_file_read_source_file
    assert_code "File.read(__FILE__)"
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
