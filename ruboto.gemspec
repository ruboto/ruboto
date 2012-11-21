require 'rake'
lib_path = File.expand_path('lib', File.dirname(__FILE__))
$:.unshift(lib_path) unless $:.include?(lib_path)
require 'ruboto/version'
require 'ruboto/description'

Gem::Specification.new do |s|
  s.name = %q{ruboto}
  s.version = Ruboto::VERSION
  s.date = Date.today.strftime '%Y-%m-%d'
  s.authors = ["Daniel Jackoway", "Charles Nutter", "Scott Moyer", 'Uwe Kubosch']
  s.email = %q{ruboto@googlegroups.com}
  s.summary = %q{A platform for developing apps using JRuby on Android.}
  s.homepage = %q{http://ruboto.org/}
  s.description = Ruboto::DESCRIPTION
  s.rubyforge_project = "ruboto/ruboto"
  s.files = FileList['[A-Z]*', "assets/**/*", "bin/*", 'lib/**/*', 'test/**/*'].to_a
  s.executables = ['ruboto']
  s.default_executable = 'ruboto'
  s.add_dependency('main', '~>4.7', '>=4.7.2')
end
