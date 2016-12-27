#!/bin/bash -e

if [ `find . -maxdepth 1 -name "jruby-jars-*.gem" | wc -l` -lt 2 ] ; then
  echo JRuby-jars gems are missing.
  rake get_jruby_jars_snapshots
else
  if [ `find . -maxdepth 1 -mtime +1 -name "jruby-jars-*.gem" | wc -l` -ne 0 ] ; then
    echo jruby-jars are old.
    rake get_jruby_jars_snapshots
  fi
fi
STABLE=`ls jruby-jars-*.gem | head -n 1 | cut -f 3 -d'-' | sed s/\\.gem//`
MASTER=`ls jruby-jars-*.gem | tail -n 1 | cut -f 3 -d'-' | sed s/\\.gem//`

# FIXME: (uwe) Test api level 25 in vagrant when abi arre available
if [[ "$TRAVIS" = "true" ]] ; then
  ANDROID_TARGETS="24 23 21 19 15" # We should cover at least 90% of the market
else
  ANDROID_TARGETS="25 24 23 21 19 15" # We should cover at least 90% of the market
fi
# EMXIF

# PLATFORM_MODES="CURRENT FROM_GEM STANDALONE"
PLATFORM_MODES="STANDALONE"
# FIXME(uwe): Add $MASTER when fixed: https://github.com/ruboto/ruboto/issues/737
STANDALONE_JRUBY_VERSIONS="1.7.25 1.7.13"
FROM_GEM_JRUBY_VERSIONS="$STABLE"
# EMXIF
RUBOTO_UPDATE_EXAMPLES=0
# STRIP_INVOKERS=1
# TEST_PART=2of4
# TEST_SCRIPT=test/ruboto_gen_test.rb
# TEST_NAME=test_activity_tests
# ACTIVITY_TEST_PATTERN=subclass

export ANDROID_OS ANDROID_TARGET RUBOTO_PLATFORM RUBOTO_UPDATE_EXAMPLES
export ACTIVITY_TEST_PATTERN STRIP_INVOKERS TEST_NAME TEST_PART TEST_SCRIPT

for ANDROID_TARGET in $ANDROID_TARGETS ; do
  ANDROID_OS=$ANDROID_TARGET

  for RUBOTO_PLATFORM in $PLATFORM_MODES ; do
    if [ "$RUBOTO_PLATFORM" == "STANDALONE" ] ; then
      jruby_versions=$STANDALONE_JRUBY_VERSIONS
    elif [ "$RUBOTO_PLATFORM" == "FROM_GEM" ] ; then
      jruby_versions=$FROM_GEM_JRUBY_VERSIONS
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
      echo -ne "\033]0;$ANDROID_TARGET $RUBOTO_PLATFORM $JRUBY_JARS_VERSION\007"

      set +e

      if [ "$RVM" != "" ] ; then
        if [ -e /etc/profile.d/rvm.sh ] ; then
          . /etc/profile.d/rvm.sh
        fi
        if [ ! $(command -v rvm) ] ; then
          echo RVM is missing!
          exit 2
        fi
        rvm --version
        unset JRUBY_HOME
        rvm install $RVM
        rvm use $RVM
        echo -n
      fi

      ./run_tests.sh

      TEST_RC=$?
      set -e

      echo ""
      echo "ANDROID_TARGET: $ANDROID_TARGET"
      echo "RUBOTO_PLATFORM: $RUBOTO_PLATFORM"
      echo "JRUBY_JARS_VERSION: $JRUBY_JARS_VERSION"
      echo "********************************************************************************"
      echo ""

      if [ "$TEST_RC" != "0" ] ; then
        echo -ne "\033]0;FAILED $ANDROID_TARGET $RUBOTO_PLATFORM $JRUBY_JARS_VERSION\007"
        echo Tests exited with code $TEST_RC
        exit $TEST_RC
      fi
    done
  done
done

echo -ne "\033]0;COMPLETED $ANDROID_TARGET $RUBOTO_PLATFORM $JRUBY_JARS_VERSION\007"
echo
echo '/-------------------------------------------------------------------------\'
echo '|                       Matrix tests completed OK!                        |'
echo '\-------------------------------------------------------------------------/'
echo
