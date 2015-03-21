require_relative 'test_helper'

class UppercasePackageNameTest < Minitest::Test

  def setup
    generate_app package: 'org.ruboto.TestApp'
  end

  def teardown
    cleanup_app
  end

  def test_gen_package_with_uppercase_name
    run_app_tests
  end
end
