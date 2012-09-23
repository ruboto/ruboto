#!/bin/bash -e

MASTER=1.7.0.preview2

export ANDROID_TARGET RUBOTO_PLATFORM JRUBY_JARS_VERSION

for ANDROID_TARGET in 10 15 ; do
  set +e
  killall emulator-arm
  sleep 5
  set -e
  if [ "$ANDROID_TARGET" == "15" ] ; then
    avd="Android_4.0.3"
  elif [ "$ANDROID_TARGET" == "10" ] ; then
    avd="Android_2.3.3"
  fi

  emulator -avd $avd -no-snapshot-load -no-snapshot-save &
  sleep 5
  adb logcat > tmp/adb_logcat.txt &
  sleep 5

  (
    set +e
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      sleep 6
      adb shell input keyevent 82 >/dev/null 2>&1
      if [ "$?" == "0" ] ; then
        echo "Unlocked screen"
        set -e
        exit 0
      fi
    done
    echo "Failed to unlock screen"
    set -e
    exit 1
  ) &

  for RUBOTO_PLATFORM in CURRENT FROM_GEM STANDALONE ; do  # CURRENT FROM_GEM STANDALONE
    if [ "$RUBOTO_PLATFORM" == "STANDALONE" ] ; then
      jruby_versions="$MASTER 1.6.8 1.6.7.2"
    elif [ "$RUBOTO_PLATFORM" == "FROM_GEM" ] ; then
      jruby_versions="$MASTER"
    elif [ "$RUBOTO_PLATFORM" == "CURRENT" ] ; then
      jruby_versions="CURRENT"
    fi
    for JRUBY_JARS_VERSION in $jruby_versions ; do
      if [ $RUBOTO_PLATFORM == "CURRENT" ] ; then
        unset JRUBY_JARS_VERSION
      fi
      echo ""
      echo "********************************************************************************"
      echo "ANDROID_TARGET: $ANDROID_TARGET"
      echo "RUBOTO_PLATFORM: $RUBOTO_PLATFORM"
      echo "JRUBY_JARS_VERSION: $JRUBY_JARS_VERSION"
      echo ""

      ./run_tests.sh
      # ruby test/minimal_app_test.rb
      # ruby test/ruboto_gen_test.rb -n test_new_apk_size_is_within_limits
      # ruby test/ruboto_gen_test.rb -n test_activity_tests
      # ruby test/ruboto_gen_test.rb -n test_handle_activity_tests
    done
  done
done
