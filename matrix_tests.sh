#!/bin/bash -e

MASTER=1.7.1.dev
PLATFORM_MODES="CURRENT FROM_GEM STANDALONE"
STANDALONE_JRUBY_VERSIONS="$MASTER 1.7.0 1.6.8"

export ANDROID_TARGET ANDROID_OS JRUBY_JARS_VERSION RUBOTO_PLATFORM
export SKIP_RUBOTO_UPDATE_TEST=1

EMULATOR_CMD=emulator64-arm

for ANDROID_TARGET in 10 15 ; do
  ANDROID_OS=$ANDROID_TARGET
  while :; do
  set +e
  killall -0 $EMULATOR_CMD 2> /dev/null
  if [ "$?" == "0" ] ; then
    killall $EMULATOR_CMD
    sleep 2
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      killall -0 $EMULATOR_CMD 2> /dev/null
      if [ "$?" != "0" ] ; then
        break
      fi
      echo "Waiting for emulator to die"
      sleep 1
    done
    killall -0 $EMULATOR_CMD 2> /dev/null
    if [ "$?" == "0" ] ; then
      echo "Emulator still running."
      killall -9 $EMULATOR_CMD
      sleep 1
    fi
  fi

  if [ "$ANDROID_TARGET" == "15" ] ; then
    avd="Android_4.0.3"
  elif [ "$ANDROID_TARGET" == "10" ] ; then
    avd="Android_2.3.3"
  fi

    set -e
    echo Start emulator
    emulator -avd $avd &

    set +e
    for i in 1 2 3 ; do
      sleep 1
      killall -0 $EMULATOR_CMD 2> /dev/null
      if [ "$?" == "0" ] ; then
        break
      fi
      echo "Waiting for emulator"
    done

    killall -0 $EMULATOR_CMD 2> /dev/null
    if [ "$?" != "0" ] ; then
      echo "Unable to start the emulator.  Retrying without loading snapshot."
      set -e
      emulator -no-snapshot-load -avd $avd &
      set +e
      for i in 1 2 3 4 5 6 7 8 9 10 ; do
        sleep 1
        killall -0 $EMULATOR_CMD 2> /dev/null
        if [ "$?" == "0" ] ; then
          break
        fi
        echo "Waiting for emulator"
      done
    fi

    killall -0 $EMULATOR_CMD 2> /dev/null
    if [ "$?" == "0" ] ; then
      echo "Emulator started."
      for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 \
               31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 ; do
        sleep 1
        if [ `adb get-state` == "device" ] ; then
          break
        fi
        echo Waiting for device: $i
      done
      if [ `adb get-state` == "device" ] ; then
        break
      fi
    fi
    echo "Unable to start the emulator."
  done
  set -e

  adb logcat > adb_logcat.log &

  (
    set +e
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      sleep 6
      adb shell input keyevent 82 >/dev/null 2>&1
      if [ "$?" == "0" ] ; then
        echo "Unlocked screen"
        set -e
        adb shell input keyevent 82 >/dev/null 2>&1
        adb shell input keyevent 4 >/dev/null 2>&1
        exit 0
      fi
    done
    echo "Failed to unlock screen"
    set -e
    exit 1
  ) &

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
      elif [ $RUBOTO_PLATFORM == "FROM_GEM" ] ; then
        rake platform:clean
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
      # ACTIVITY_TEST_PATTERN=subclass ruby test/ruboto_gen_test.rb -n test_activity_tests
      # ACTIVITY_TEST_PATTERN=mytest ruby test/ruboto_gen_test.rb -n test_activity_tests
      # ruby test/ruboto_gen_test.rb -n test_handle_activity_tests
      # ruby test/ruboto_gen_test.rb -n test_activity_with_first_letter_lower_case_in_name
    done
  done
done
