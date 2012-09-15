#!/bin/bash -e

for platform in CURRENT FROM_GEM STANDALONE ; do  # CURRENT FROM_GEM STANDALONE
  echo "platform: $platform"
  for target in 15 10 ; do
    echo "target: $target"
    set +e
    killall emulator-arm
    sleep 5
    set -e
    if [ "$target" == "15" ] ; then
      avd="Android_4.0.3"
    elif [ "$target" == "10" ] ; then
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
        echo "Unlocking screen"
        adb shell input keyevent 82
        if [ "$?" == "0" ] ; then
          set -e
          exit 0
        fi
      done
      set -e
      exit 1
    ) &

    if [ "$platform" == "STANDALONE" ] ; then
      jruby_versions="1.7.0.preview2 1.6.7"
    elif [ "$platform" == "FROM_GEM" ] ; then
      jruby_versions="1.7.0.preview2"
    elif [ "$platform" == "CURRENT" ] ; then
      jruby_versions="1.7.0.preview2"  # THIS IS STUPID!
    fi
    for jruby_version in "$jruby_versions" ; do
      echo "jruby version: $jruby_version"
      export RUBOTO_PLATFORM=$platform
      export ANDROID_TARGET=$target
      export JRUBY_JARS_VERSION=$jruby_version

      # ./run_tests.sh
      ruby test/ruboto_gen_test.rb -n test_activity_tests
      # ruby test/ruboto_gen_test.rb -n test_handle_activity_tests
    done
  done
done
