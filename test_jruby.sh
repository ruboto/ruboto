#!/bin/bash -e

# This script can be run with "git bisect run" to determine which JRuby commit broke the tests
# Change the test run at the bottom to narrow down the test and make it faster.
# cd jruby
# git bisect start HEAD <good revision>
# git bisect run ../ruboto/test_jruby.sh

JRUBY_HOME=`pwd`
RUBOTO_HOME=`dirname $0`

if [ ! -e "LICENSE.RUBY" ] ; then
  echo "You must cd to the jruby working copy before running this script."
  exit 1
fi

ant clean dist-clean
ant dist

cd $RUBOTO_HOME

export GEM_HOME=$RUBOTO_HOME/tmp/gems
export GEM_PATH=$GEM_HOME
bundle install
gem uninstall jruby-jars --all
gem install -l $JRUBY_HOME/dist/jruby-jars-*.gem

rm -rf tmp/Ruboto*

ruby test/ruboto_gen_test.rb -n test_activity_tests
# ruby test/broadcast_receiver_test.rb -n test_generated_broadcast_receiver
