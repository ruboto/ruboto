require 'test/unit'

PROJECT_DIR = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH << PROJECT_DIR

gem_spec = Gem.searcher.find('jruby-jars')
raise StandardError.new("Can't find Gem specification jruby-jars.") unless gem_spec
JRUBY_JARS_VERSION = gem_spec.version
ON_JRUBY_JARS_1_5_6 = JRUBY_JARS_VERSION == Gem::Version.new('1.5.6')

PACKAGE ='org.ruboto.test_app'
APP_NAME = 'RubotoTestApp'
TMP_DIR = File.join PROJECT_DIR, 'tmp'
APP_DIR = File.join TMP_DIR, APP_NAME
ANDROID_TARGET = ENV['ANDROID_TARGET'] || 'android-8'
