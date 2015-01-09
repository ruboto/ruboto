require File.expand_path("test_helper", File.dirname(__FILE__))

class GemTest < Minitest::Test
  def test_rake_gem
    gem_file = "ruboto-#{Ruboto::VERSION}.gem"
    File.delete(gem_file) if File.exists?(gem_file)
    assert !File.exists?(gem_file)
    system 'rake gem'
    assert File.exists?(gem_file)
  end

end
