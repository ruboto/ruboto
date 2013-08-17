require File.expand_path('test_helper', File.dirname(__FILE__))

class UppercasePackageNameTest < Test::Unit::TestCase

  def setup
    puts "test running"
    generate_app :package => "org.ruboto.TestApp"
  end

  def teardown
    cleanup_app
  end

  def test_gen_package_with_uppercase_name
    check_platform_installation
    run_app_tests
  end
end
