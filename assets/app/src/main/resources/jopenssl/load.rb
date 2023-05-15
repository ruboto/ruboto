warn 'Loading jruby-openssl gem in a non-JRuby interpreter' unless defined? JRUBY_VERSION

require 'jopenssl/version'

# NOTE: assuming user does pull in BC .jars from somewhere else on the CP
unless ENV_JAVA['jruby.openssl.load.jars'].eql?('false')
  version = JOpenSSL::BOUNCY_CASTLE_VERSION
  begin
    require 'jar-dependencies'
    # if we have jar-dependencies we let it track the jars
    require_jar 'org.bouncycastle', 'bcprov-jdk18on', version
    require_jar 'org.bouncycastle', 'bcpkix-jdk18on', version
    require_jar 'org.bouncycastle', 'bcutil-jdk18on', version
    require_jar 'org.bouncycastle', 'bctls-jdk18on',  version
    bc_jars = true
  rescue LoadError, RuntimeError
    bc_jars = false
  end
  unless bc_jars
    load "org/bouncycastle/bcprov-jdk18on/#{version}/bcprov-jdk18on-#{version}.jar"
    load "org/bouncycastle/bcpkix-jdk18on/#{version}/bcpkix-jdk18on-#{version}.jar"
    load "org/bouncycastle/bcutil-jdk18on/#{version}/bcutil-jdk18on-#{version}.jar"
    load "org/bouncycastle/bctls-jdk18on/#{version}/bctls-jdk18on-#{version}.jar"
  end
end

require 'jopenssl.jar'

if JRuby::Util.respond_to?(:load_ext) # JRuby 9.2
  JRuby::Util.load_ext('org.jruby.ext.openssl.OpenSSL')
else; require 'jruby'
  org.jruby.ext.openssl.OpenSSL.load(JRuby.runtime)
end

if RUBY_VERSION > '2.3'
  load "jopenssl/compat23.rb"
end

# NOTE: content bellow should live in *lib/openssl.rb* but due RubyGems/Bundler
# `autoload :OpenSSL` this will cause issues if an older version (0.11) is the
# default gem under JRuby 9.2 (which on auto-load does not trigger a dynamic
# require - this is only fixed in JRuby 9.3)

module OpenSSL
  autoload :Config, 'openssl/config' unless const_defined?(:Config, false)
  autoload :PKCS12, 'openssl/pkcs12'
end

=begin
= Info
  'OpenSSL for Ruby 2' project
  Copyright (C) 2002  Michal Rokos <m.rokos@sh.cvut.cz>
  All rights reserved.

= Licence
  This program is licensed under the same licence as Ruby.
  (See the file 'LICENCE'.)
=end

require 'openssl/bn'
require 'openssl/pkey'
require 'openssl/cipher'
#require 'openssl/config' if OpenSSL.const_defined?(:Config, false)
require 'openssl/digest'
require 'openssl/hmac'
require 'openssl/x509'
require 'openssl/ssl'
require 'openssl/pkcs5'

module OpenSSL
  # call-seq:
  #   OpenSSL.secure_compare(string, string) -> boolean
  #
  # Constant time memory comparison. Inputs are hashed using SHA-256 to mask
  # the length of the secret. Returns +true+ if the strings are identical,
  # +false+ otherwise.
  def self.secure_compare(a, b)
    hashed_a = OpenSSL::Digest.digest('SHA256', a)
    hashed_b = OpenSSL::Digest.digest('SHA256', b)
    OpenSSL.fixed_length_secure_compare(hashed_a, hashed_b) && a == b
  end
end