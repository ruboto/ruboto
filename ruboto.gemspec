require 'date'
lib_path = File.expand_path('lib', File.dirname(__FILE__))
$:.unshift(lib_path) unless $:.include?(lib_path)
require 'ruboto/version'
require 'ruboto/description'

Gem::Specification.new do |s|
  s.name = %q{ruboto}
  s.version = Ruboto::VERSION
  s.date = Date.today.strftime '%Y-%m-%d'
  s.authors = ['Daniel Jackoway', 'Charles Nutter', 'Scott Moyer', 'Uwe Kubosch']
  s.email = %q{ruboto@googlegroups.com}
  s.homepage = %q{http://ruboto.org/}
  s.summary = %q{A platform for developing apps using JRuby on Android.}
  s.description = Ruboto::DESCRIPTION
  s.rubyforge_project = 'ruboto/ruboto'
  s.license = 'MIT'
  s.files = Dir['[A-Z]*'].select{|f| f =~ /^[A-Z]/} + Dir['assets/**/{*,.*}', 'bin/*', 'lib/**/*', 'test/**/*']
  s.executables = %w(ruboto)

  s.add_runtime_dependency 'main', '~>6.0' # TODO(uwe): Switch to stdlib OptionParser for less depency
  # s.add_runtime_dependency 'net-telnet', '~>0.1.1'
  s.add_runtime_dependency 'rake', '>=11.3', '<13'
  s.add_runtime_dependency 'rexml', '~> 3.2'
  s.add_runtime_dependency 'rubyzip', '~>1.0'
end
