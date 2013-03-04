#!/bin/bash -e

if [ `uname -m` == "x86_64" ] ; then
  EMULATOR_CMD=emulator64-arm
else
  EMULATOR_CMD=emulator-arm
fi

EMULATOR_OPTS="-partition-size 128"
if [ "$DISPLAY" == "" ] ; then
  EMULATOR_OPTS="$EMULATOR_OPTS -no-window -no-audio"
fi

while :; do
  set +e
  killall -0 $EMULATOR_CMD 2> /dev/null
  if [ "$?" == "0" ] ; then
    killall $EMULATOR_CMD
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      killall -0 $EMULATOR_CMD 2> /dev/null
      if [ "$?" != "0" ] ; then
        break
      fi
      if [ $i == 3 ] ; then
        echo -n "Waiting for emulator to die: ..."
      elif [ $i -gt 3 ] ; then
        echo -n .
      fi
      sleep 1
    done
    echo
    killall -0 $EMULATOR_CMD 2> /dev/null
    if [ "$?" == "0" ] ; then
      echo "Emulator still running."
      killall -9 $EMULATOR_CMD
      sleep 1
    fi
  fi

  if [ "$ANDROID_TARGET" == "17" ] ; then
    AVD="Android_4.2"
    ABI_OPT="--abi armeabi-v7a"
  elif [ "$ANDROID_TARGET" == "16" ] ; then
    AVD="Android_4.1.2"
    ABI_OPT="--abi armeabi-v7a"
  elif [ "$ANDROID_TARGET" == "15" ] ; then
    AVD="Android_4.0.3"
    ABI_OPT="--abi armeabi-v7a"
  elif [ "$ANDROID_TARGET" == "13" ] ; then
    AVD="Android_3.2"
    ABI_OPT="--abi armeabi-v7a"
  elif [ "$ANDROID_TARGET" == "11" ] ; then
    AVD="Android_3.0"
    ABI_OPT="--abi armeabi-v7a"
  elif [ "$ANDROID_TARGET" == "10" ] ; then
    AVD="Android_2.3.3"
    ABI_OPT="--abi armeabi"
  else
    echo Unknown api level: $ANDROID_TARGET
    exit 2
  fi

  if [ "`ls -d ~/.android/avd/$AVD.avd 2>/dev/null`" == "" ] ; then
    echo Creating AVD $AVD
    sed -i.bak -e "s/vm.heapSize=24/vm.heapSize=48/" ${ANDROID_HOME}/platforms/*/*/*/hardware.ini
    echo n | android create avd -a -n $AVD -t android-$ANDROID_TARGET $ABI_OPT -c 64M -s HVGA
    sed -i.bak -e "s/vm.heapSize=24/vm.heapSize=48/" ~/.android/avd/$AVD.avd/config.ini
  fi

  set -e
  echo Start emulator
  emulator -avd $AVD $EMUALTOR_OPTS &

  set +e
  for i in 1 2 3 ; do
    sleep 1
    killall -0 $EMULATOR_CMD 2> /dev/null
    if [ "$?" == "0" ] ; then
      unset NEW_SNAPSHOT
      break
    fi
    if [ $i == 3 ] ; then
      echo -n "Waiting for emulator: ..."
    elif [ $i -gt 3 ] ; then
        echo -n .
    fi
  done
  echo
  killall -0 $EMULATOR_CMD 2> /dev/null
  if [ "$?" != "0" ] ; then
    echo "Unable to start the emulator.  Retrying without loading snapshot."
    set -e
    emulator -no-snapshot-load -avd $AVD $EMULATOR_OPTS &
    set +e
    for i in 1 2 3 4 5 6 7 8 9 10 ; do
      killall -0 $EMULATOR_CMD 2> /dev/null
      if [ "$?" == "0" ] ; then
        NEW_SNAPSHOT=1
        break
      fi
      if [ $i == 3 ] ; then
        echo -n "Waiting for emulator: ..."
      elif [ $i -gt 3 ] ; then
          echo -n .
      fi
      sleep 1
    done
  fi

  killall -0 $EMULATOR_CMD 2> /dev/null
  if [ "$?" == "0" ] ; then
    echo -n "Emulator started: "
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 \
             31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 ; do
      if [ "`adb get-state`" == "device" ] ; then
        break
      fi
      echo -n .
      sleep 1
    done
    echo
    if [ `adb get-state` == "device" ] ; then
      break
    fi
  fi
  echo "Unable to start the emulator."
done
set -e

if [ "$NEW_SNAPSHOT" == "1" ] ; then
  echo Allow the emulator to calm down a bit.
  sleep 15
fi

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

adb logcat > adb_logcat.log &

echo Emulator $AVD started OK.
