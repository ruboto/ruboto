require 'rake'
require 'lib/ruboto/version'

Gem::Specification.new do |s|
  s.name = %q{ruboto}
  s.version = Ruboto::VERSION
  s.date = Date.today.strftime '%Y-%m-%d'
  s.authors = ["Daniel Jackoway", "Charles Nutter", "Scott Moyer", 'Uwe Kubosch']
  s.email = %q{ruboto@googlegroups.com}
  s.summary = %q{Platform for writing Android apps in Ruby}
  s.homepage = %q{http://ruboto.org/}
  s.description = %Q{Ruboto - JRuby on Android\nA generator and framework for developing full stand-alone apps for Android.}
  s.rubyforge_project = "ruboto/ruboto-core"
  s.files = FileList['[A-Z]*', "assets/**/*", "bin/*", 'lib/**/*', 'test/**/*'].to_a
  s.executables = ['ruboto']
  s.default_executable = 'ruboto'
  s.add_dependency('main', '~>4.7', '>=4.7.2')
  # s.add_dependency('jruby-jars', '>=1.5.6')
end
