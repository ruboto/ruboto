require 'rake'
require 'lib/ruboto/version'

Gem::Specification.new do |s|
  s.name = %q{ruboto-core}
  s.version = Ruboto::VERSION
  s.date = Date.today.strftime '%Y-%m-%d'
  s.authors = ["Daniel Jackoway", "Charles Nutter", "Scott Moyer", 'Uwe Kubosch']
  s.email = %q{ruboto@googlegroups.com}
  s.summary = %q{Platform for writing Android apps in Ruby}
  s.homepage = %q{http://ruboto.org/}
  s.description = %q{Obsolete package.  Use the "ruboto" gem instead.}
  s.rubyforge_project = "ruboto/ruboto-core"
  s.files = []
  s.add_dependency('ruboto', ">=#{Ruboto::VERSION}")
  s.post_install_message = <<-EOF
    
    This gem has been renamed to "ruboto".
    Please use the "ruboto" gem in the future.
    
  EOF
end
