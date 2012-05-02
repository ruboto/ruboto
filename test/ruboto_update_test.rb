require File.expand_path('updated_example_test_methods', File.dirname(__FILE__))
require File.expand_path('update_test_methods', File.dirname(__FILE__))

# TODO(uwe): Delete obsolete examples when we stop supporting updating from them.

Dir.chdir "#{RubotoTest::PROJECT_DIR}/examples/" do
  Dir["#{RubotoTest::APP_NAME}_*_tools_r*.tgz"].each do |f|
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
