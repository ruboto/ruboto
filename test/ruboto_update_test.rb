if ENV['SKIP_RUBOTO_UPDATE_TEST']
  puts 'Detected SKIP_RUBOTO_UPDATE_TEST environment variable.  Skipping Ruboto update test.'
  example_limit = 0
elsif ENV['RUBOTO_UPDATE_EXAMPLES']
  example_limit = ENV['RUBOTO_UPDATE_EXAMPLES'].to_i
  puts "Detected RUBOTO_UPDATE_EXAMPLES environment variable.  Limiting to #{example_limit} examples."
end
require File.expand_path('updated_example_test_methods', File.dirname(__FILE__))
require File.expand_path('update_test_methods', File.dirname(__FILE__))

# TODO(uwe): Delete obsolete examples when we stop supporting updating from them.
Dir.chdir "#{RubotoTest::PROJECT_DIR}/examples/" do
  example_archives = Dir["#{RubotoTest::APP_NAME}_*_tools_r*.tgz"]
  example_archives = example_archives.sort_by { |a| Gem::Version.new(a[RubotoTest::APP_NAME.size + 1..-1].slice(/(.*)(?=_tools_)/).gsub('_', '.')) }
  example_archives = example_archives.last(example_limit) if example_limit
  examples = example_archives.collect { |f| f.match /^#{RubotoTest::APP_NAME}_(?<ruboto_version>.*)_tools_r(?<tools_version>.*)\.tgz$/ }.compact

  # TODO(gf): Track APIs compatible with update examples
  # EXAMPLE_COMPATIBLE_APIS = {(Gem::Version.new('0.7.0')..Gem::Version.new('0.10.99')) => [8],
  #                            (Gem::Version.new('0.11.0')..Gem::Version.new('0.13.0')) => [10, 11, 12, 13, 14, 15, 16, 17]}
  # installed_apis = `android list target --compact`.lines.grep(/^android-/) { |s| s.match(/\d+/).to_s.to_i }
  # missing_apis = false
  # puts "Backward compatibility update tests: #{examples.size}"
  # examples.each_with_index do |m, i|
  #   example_gem_version = Gem::Version.new m[:ruboto_version]
  #   compatible_apis = EXAMPLE_COMPATIBLE_APIS[EXAMPLE_COMPATIBLE_APIS.keys.detect { |gem_range| gem_range.cover? example_gem_version }]
  #   if compatible_apis
  #     if (installed_apis & compatible_apis).empty?
  #       puts "Update test #{example_archives[i]} needs a missing compatible API: #{compatible_apis.join(',')}"
  #       # missing_apis = true
  #     end
  #   end
  # end
  #
  # if missing_apis
  #   puts '----------------------------------------------------------------------------------------------------'
  #   puts 'Required android APIs are missing, resolution options are:'
  #   puts '* Install a needed android API with "android update sdk --no-ui --all --filter android-XX"'
  #   puts '* Skip all backward compatibility update tests with "SKIP_RUBOTO_UPDATE_TEST=DEFINED rake test"'
  #   puts '* Limit number of backward compatibility update tests to N with "RUBOTO_UPDATE_EXAMPLES=N rake test"'
  #   puts 'Quitting...'
  #   exit false
  # end

  examples.each do |m|
    ruboto_version = m[:ruboto_version]
    tools_version = m[:tools_version]
    ruboto_version_no_dots = ruboto_version.gsub('.', '_')
    self.class.class_eval <<EOF
class RubotoUpdatedExample#{ruboto_version_no_dots}Tools#{tools_version}Test < Minitest::Test
  include UpdatedExampleTestMethods
  def setup
    super('#{ruboto_version}', '#{tools_version}')
  end
end

class RubotoUpdate#{ruboto_version_no_dots}Tools#{tools_version}Test < Minitest::Test
  include UpdateTestMethods
  def setup
    super('#{ruboto_version}', '#{tools_version}')
  end
end
EOF
  end

end

class RubotoUpdateTest < Minitest::Test
  def setup
    generate_app :heap_alloc => 16, :update => true
  end

  def teardown
    cleanup_app
  end

  def test_jruby_adapter_heap_alloc
    Dir.chdir APP_DIR do
      assert_match /^\s*byte\[\] arrayForHeapAllocation = new byte\[16 \* 1024 \* 1024\];/,
                     File.read('src/org/ruboto/JRubyAdapter.java')
    end
  end
end
