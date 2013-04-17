#!/bin/bash -e

ANDROID_TARGETS="10 15 16" # We should cover at least 80% of the market
PLATFORM_MODES="CURRENT FROM_GEM STANDALONE"
MASTER=`ls jruby-jars-*.dev.gem | tail -n 1 | cut -f 3 -d'-' | cut -f1-4 -d'.'`
STANDALONE_JRUBY_VERSIONS="$MASTER 1.7.3"
RUBOTO_UPDATE_EXAMPLES=1

export ANDROID_TARGET ANDROID_OS RUBOTO_PLATFORM RUBOTO_UPDATE_EXAMPLES

for ANDROID_TARGET in $ANDROID_TARGETS ; do
  ANDROID_OS=$ANDROID_TARGET

  . ./start_emulator.sh

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

      ./run_tests.sh
      # ./run_tests.sh TEST=test/ruboto_update_test.rb
      # testrb test/ruboto_gen_test.rb -n test_new_apk_size_is_within_limits
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
        exit $TEST_RC
      fi
    done
  done
done

echo Matrix tests completed OK!
