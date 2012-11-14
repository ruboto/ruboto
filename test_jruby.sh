#!/bin/bash

# This script can be run with "git bisect run" to determine which JRuby commit broke the tests.
# Change the test run at the bottom to narrow down the test and make it faster.
# cd ../jruby
# git bisect start
# git bisect good `git rev-list -n 1 --before="2011-10-27 13:37" master`
# git bisect bad HEAD
# git bisect run ../ruboto/test_jruby.sh

# When you are finished run

# git bisect reset



JRUBY_HOME=`pwd`
RUBOTO_HOME=`dirname $0`

if [ ! -e "LICENSE.RUBY" ] ; then
  echo "You must cd to the jruby working copy before running this script."
  exit 1
fi

echo Remaining suspects: `git bisect view | grep "Date:" | wc -l`

ant clean-all dist-gem
build_status=$?

# Only needed to bisect source older than JRuby 1.7.0.rc1
if [ $build_status -ne 0 ] ; then
  echo Build failed.  Trying older ANT target.
  ant clean-all dist-jar-complete
  if [ $? -eq 0 ] ; then
    bin/rake gem
  fi
  build_status=$?
fi

rm lib/native/Darwin/libjruby-cext.jnilib
git checkout .
git checkout lib/native/Darwin/libjruby-cext.jnilib
if [ $build_status -eq 0 ] ; then
  echo Build OK.
else
  echo "Build failed, skipping revision"
  exit 125
fi

set -e

cd $RUBOTO_HOME

export GEM_HOME=$RUBOTO_HOME/tmp/gems
export GEM_PATH=$GEM_HOME
unset JRUBY_JARS_VERSION        # The version may vary across revisions
export RUBOTO_PLATFORM=FROM_GEM # Avoid the CURRENT setting since it ignores our GEM
bundle install
gem uninstall jruby-jars --all
gem install -l $JRUBY_HOME/dist/jruby-jars-*.gem

rm -rf tmp/Ruboto*

set +e

./matrix_tests.sh
# ./run_tests.sh
# ruby test/broadcast_receiver_test.rb -n test_generated_broadcast_receiver
# ACTIVITY_TEST_PATTERN=subclass ruby test/ruboto_gen_test.rb -n test_activity_tests
# ruby test/ruboto_gen_test.rb -n test_block_def_activity_tests

test_status=$?
echo
echo "********************************************************************************"
if [ $test_status -eq 0 ] ; then
  echo Bisect GOOD.
else
  echo Bisect BAD.
fi
echo "********************************************************************************"
echo

exit $test_status
