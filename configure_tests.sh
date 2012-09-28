#!/bin/bash -e

export RUBY_IMPL=""              # an rvm ruby id : jruby|rbx|ruby-1.8.7|ruby-1.9.3 : default is to use the system Ruby
export RUBOTO_PLATFORM=FROM_GEM  # CURRENT|FROM_GEM|STANDALONE : default = CURRENT
export ANDROID_TARGET=15                 # Default is 8
export JRUBY_JARS_VERSION=1.7.0.rc1 # Default is use the installed gem with the highest version
