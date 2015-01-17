#!/bin/bash -e

(gem query -i -q -n ruboto > /dev/null) || rake install

if [ `find . -maxdepth 1 -name "jruby-jars-*.gem" | wc -l` -lt 2 ] ; then
  echo JRuby-jars gems are missing.
  rake get_jruby_jars_snapshots
else
  if [ `find . -maxdepth 1 -mtime +1 -name "jruby-jars-*.gem" | wc -l` -ne 0 ] ; then
    echo jruby-jars are old.
    rake get_jruby_jars_snapshots
  fi
fi

ANDROID_TARGETS="21 19 17 16 15" # We should cover at least 90% of the market
PLATFORM_MODES="CURRENT FROM_GEM STANDALONE"
STABLE=`ls jruby-jars-*.gem | head -n 1 | cut -f 3 -d'-' | sed s/\\.gem//`
MASTER=`ls jruby-jars-*.gem | tail -n 1 | cut -f 3 -d'-' | sed s/\\.gem//`
STANDALONE_JRUBY_VERSIONS="$MASTER $STABLE 1.7.18"
RUBOTO_UPDATE_EXAMPLES=1
# STRIP_INVOKERS=1
# TEST_PART=4of5

export ANDROID_OS ANDROID_TARGET RUBOTO_PLATFORM RUBOTO_UPDATE_EXAMPLES
export STRIP_INVOKERS TEST_PART

for ANDROID_TARGET in $ANDROID_TARGETS ; do
  ANDROID_OS=$ANDROID_TARGET

  ruboto setup -y -t 10 -t $ANDROID_OS
  source ~/.rubotorc
  ruboto emulator -t $ANDROID_OS

  for RUBOTO_PLATFORM in $PLATFORM_MODES ; do
    if [ "$RUBOTO_PLATFORM" == "STANDALONE" ] ; then
      jruby_versions=$STANDALONE_JRUBY_VERSIONS
    elif [ "$RUBOTO_PLATFORM" == "FROM_GEM" ] ; then
      jruby_versions="$MASTER $STABLE"
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
      # ruby test/ruboto_gen_test.rb -n test_new_apk_size_is_within_limits
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

echo
echo '/-------------------------------------------------------------------------\'
echo '|                       Matrix tests completed OK!                        |'
echo '\-------------------------------------------------------------------------/'
echo
