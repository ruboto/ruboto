#!/bin/bash -e

if [ -z `find . -name "jruby-jars-*.dev.gem" -maxdepth 1` ] ; then
  echo JRuby-jars master gem is missing.
  rake get_jruby_jars_snapshot
else
  if [ `find . -name "jruby-jars-*.dev.gem" -mtime +1d -maxdepth 1` ] ; then
    echo jruby-jars master is old.
    rake get_jruby_jars_snapshot
  fi
fi

ANDROID_TARGETS="16 17 15 18 19" # We should cover at least 90% of the market
PLATFORM_MODES="CURRENT FROM_GEM STANDALONE"
MASTER=`ls jruby-jars-*.dev.gem | tail -n 1 | cut -f 3 -d'-' | sed s/\\.gem//`
STANDALONE_JRUBY_VERSIONS="$MASTER 1.7.11 1.7.10 1.7.4"
RUBOTO_UPDATE_EXAMPLES=1
# export STRIP_INVOKERS=1

export ANDROID_TARGET ANDROID_OS RUBOTO_PLATFORM RUBOTO_UPDATE_EXAMPLES

for ANDROID_TARGET in $ANDROID_TARGETS ; do
  ANDROID_OS=$ANDROID_TARGET

  ruboto setup -y -t 10 -t $ANDROID_OS
  source ~/.rubotorc
  ruboto emulator -t $ANDROID_OS

  for RUBOTO_PLATFORM in $PLATFORM_MODES ; do
    if [ "$RUBOTO_PLATFORM" == "STANDALONE" ] ; then
      jruby_versions=$STANDALONE_JRUBY_VERSIONS
    elif [ "$RUBOTO_PLATFORM" == "FROM_GEM" ] ; then
      jruby_versions="$MASTER"
    elif [ "$RUBOTO_PLATFORM" == "CURRENT" ] ; then
      jruby_versions="CURRENT"
    fi
    for JRUBY_JARS_VERSION in $jruby_versions ; do
      if [ $RUBOTO_PLATFORM == "CURRENT" ] ; then
        unset JRUBY_JARS_VERSION
      else
        export JRUBY_JARS_VERSION
        if [ $RUBOTO_PLATFORM == "FROM_GEM" ] ; then
          rake platform:clean
        fi
      fi
      echo ""
      echo "********************************************************************************"
      echo "ANDROID_TARGET: $ANDROID_TARGET"
      echo "RUBOTO_PLATFORM: $RUBOTO_PLATFORM"
      echo "JRUBY_JARS_VERSION: $JRUBY_JARS_VERSION"
      echo ""

      set +e

      # ./run_tests.sh
      # ./run_tests.sh TEST=test/ruboto_update_test.rb
      testrb test/rake_test.rb -n test_that_update_scripts_task_copies_files_to_sdcard_and_are_read_by_activity
      # ACTIVITY_TEST_PATTERN=subclass testrb test/ruboto_gen_test.rb -n test_activity_tests

      TEST_RC=$?
      set -e

      echo ""
      echo "ANDROID_TARGET: $ANDROID_TARGET"
      echo "RUBOTO_PLATFORM: $RUBOTO_PLATFORM"
      echo "JRUBY_JARS_VERSION: $JRUBY_JARS_VERSION"
      echo "********************************************************************************"
      echo ""

      if [ "$TEST_RC" != "0" ] ; then
        echo Tests exited with code $TEST_RC
        exit $TEST_RC
      fi
    done
  done
done

echo Matrix tests completed OK!
