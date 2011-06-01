require "test/unit"

PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH << PROJECT_DIR

def jruby_jars_version
  gem_spec = Gem.searcher.find('jruby-jars')
  if not gem_spec
    raise StandardError.new("Can't find Gem specification for path \"#{'jruby-jars'}\".")
  end
  gem_spec.version
end

puts 'jruby_jars_version:'
p jruby_jars_version

ON_JRUBY_JARS_1_5_6 = jruby_jars_version == Gem::Version.new('1.5.6')

puts 'ON_JRUBY_JARS_1_5_6:'
p ON_JRUBY_JARS_1_5_6