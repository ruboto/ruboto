require 'rake'
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
  s.files = FileList['[A-Z]*'].to_a.select{|f| f =~ /^[A-Z]/} + FileList['assets/**/{*,.*}', 'bin/*', 'lib/**/*', 'test/**/*'].to_a
  s.executables = %w(ruboto)
  s.default_executable = 'ruboto'
  s.add_runtime_dependency 'main', '~>5.2'
  s.add_runtime_dependency 'net-telnet', '~>0.1.1'
  s.add_runtime_dependency 'rake', '~>10.0'
  s.add_runtime_dependency 'rubyzip', '~>1.0'
  s.add_development_dependency 'minitest', '~>5.5'

  # jruby-jars is only necessary for standalone apps.
  # It will be installed on demand.
  # s.add_dependency('jruby-jars')
end
