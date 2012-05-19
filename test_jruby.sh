#!/bin/bash -e

# This script can be run with "git bisect run" to determine which JRuby commit broke the tests
# Change the test run at the bottom to narrow down the test and make it faster.

JRUBY_HOME=`pwd`
RUBOTO_HOME=`dirname $0`
GEM_HOME=$RUBOTO_HOME/tmp

if [ ! -e "LICENSE.RUBY" ] ; then
  echo "You must cd to the jruby working copy before running this script."
  exit 1
fi

ant clean dist-clean
ant dist

cd $RUBOTO_HOME

if [ -d "$RUBOTO_HOME/tmp/1.8" ] ; then
  bundle install
fi

gem install $JRUBY_HOME/dist/jruby-jars-1.7.0.preview1.gem

rm -rf tmp/Ruboto*
ruby test/ruboto_gen_test.rb -n test_activity_tests
