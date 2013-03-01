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
  example_archives.sort_by!{|a| Gem::Version.new a.slice(/(?<=#{RubotoTest::APP_NAME}_)(.*)(?=_tools_)/)}
  example_archives = example_archives.last(example_limit) if example_limit
  example_archives.each do |f|
    next unless f =~ /^#{RubotoTest::APP_NAME}_(.*)_tools_r(.*)\.tgz$/
    ruboto_version = $1
    tools_version = $2
    self.class.class_eval <<EOF
class RubotoUpdatedExample#{ruboto_version.gsub('.', '_')}Tools#{tools_version}Test < Test::Unit::TestCase
  include UpdatedExampleTestMethods
  def setup
    super('#{ruboto_version}', '#{tools_version}')
  end
end

class RubotoUpdate#{ruboto_version.gsub('.', '_')}Tools#{tools_version}Test < Test::Unit::TestCase
  include UpdateTestMethods
  def setup
    super('#{ruboto_version}', '#{tools_version}')
  end
end
EOF
  end
end
