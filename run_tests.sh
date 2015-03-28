#!/bin/bash -el

# This script expects environment variables already set, and configures the
# environment before starting the tests.  The environment variables can be set
# manually, by matrix_tests.sh or by travis-ci.  The script should self-destruct
# after a timeout to avoid running forever with hung tests.

echo "Starting tests..."

killtree() {
    local parent=$1 child
    for child in $(ps -o ppid= -o pid= | awk "\$1==$parent {print \$2}"); do
        killtree $child
    done
    kill -9 $parent
}

# BEGIN TIMEOUT #
TIMEOUT=3000 # 50 minutes
BOSSPID=$$
(
  sleep $TIMEOUT
  echo
  echo "Test timed out after $TIMEOUT seconds."
  echo
  killtree -$BOSSPID
  echo
  echo Emulator log:
  echo
  cat adb_logcat.log
  echo
  echo "Test timed out after $TIMEOUT seconds."
)&
TIMERPID=$!
echo "PIDs: Boss: $BOSSPID, Timer: $TIMERPID"

trap "killtree $TIMERPID" EXIT
# END TIMEOUT #

rake install
ruboto setup -y -t $ANDROID_TARGET
source ~/.rubotorc

ruboto emulator -t $ANDROID_TARGET --no-snapshot
> adb_logcat.log

(gem query -q -i -n bundler >/dev/null) || gem install bundler
bundle install

export NOEXEC_DISABLE=1
rake clean
set +e
if [ "$TEST_NAME" != "" ] ; then
  TEST_NAME_ARG="-n $TEST_NAME"
fi
if [ "$TEST_SCRIPT" != "" ] ; then
  ruby $TEST_SCRIPT $TEST_NAME_ARG
else
  rake test $* $TEST_NAME_ARG
fi
TEST_RC=$?
set -e

echo Tests exited with code $TEST_RC

if [ "$TEST_RC" != "0" ] ; then
  echo
  echo Emulator log:
  echo
  cat adb_logcat.log
  echo
  echo Tests failed with exit code $TEST_RC
fi

exit $TEST_RC
