require_relative 'test_helper'

class DebuggerTest < Minitest::Test

  def setup
    generate_app bundle: [
      [ 'columnize',       '~> 0.9.0' ],
      [ 'linecache',       '~> 1.3.1' ],
      [ 'ruby-debug-base', '~> 0.10.6' ],
      [ 'ruby-debug',      '~> 0.10.6' ],
    ]
  end

  def teardown
    cleanup_app
  end

  def test_app_works
    run_app_tests
  end

  # def test_app_debugs
  # end

end

