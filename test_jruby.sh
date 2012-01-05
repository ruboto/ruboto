#!/bin/bash -e

JRUBY_HOME=`pwd`
RUBOTO_HOME=`dirname $0`

if [ ! -e "LICENSE.RUBY" ] ; then
  echo "You must cd to the jruby working copy before running this script."
  exit 1
fi

ant clean dist-clean
ant dist
gem install dist/jruby-jars-1.7.0.dev.gem

cd $RUBOTO_HOME
rm -rf tmp/Ruboto*
ruby test/ruboto_gen_test.rb -n test_activity_tests
