require 'rake'

Gem::Specification.new do |s|
  s.name = %q{ruboto-core}
  s.version = "0.0.1"
  s.date = %q{2010-07-29}
  s.authors = ["Daniel Jackoway"]
  s.email = %q{ruboto@googlegroups.com}
  s.summary = %q{The core components of Ruby on Android}
  s.homepage = %q{http://ruboto.org/}
  s.description = %q{The core components of Ruby on Android}
  s.files = FileList['[A-Z]*', "assets/**/*", "bin/*", 'lib/*'].to_a
  s.executables = ['ruboto']
  s.default_executable = 'ruboto'
  s.add_dependency('main', '= 4.2.0')
  s.add_dependency('jruby-jars', '>= 1.5.0')
end
