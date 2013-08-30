require File.expand_path('test_helper', File.dirname(__FILE__))

class UppercasePackageNameTest < Test::Unit::TestCase

  def setup
    generate_app :package => 'org.ruboto.TestApp'
  end

  def teardown
    cleanup_app
  end

  def test_gen_package_with_uppercase_name
    run_app_tests
  end
end
