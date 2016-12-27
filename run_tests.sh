#!/bin/bash -el

# This script expects environment variables already set, and configures the
# environment before starting the tests.  The environment variables can be set
# manually, by matrix_tests.sh or by travis-ci.  The script should self-destruct
# after a timeout to avoid running forever with hung tests.

echo "Starting tests..."

killtree() {
    local parent=$1 child
    if [[ "$1" == "$BASHPID" ]] ; then
      return
    fi
    for child in $(ps -o ppid= -o pid= | awk "\$1==$parent {print \$2}"); do
        killtree $child
    done
    { kill -0 $parent 2> /dev/null && kill -9 $parent ; } || echo Process $parent finished.
}

# BEGIN TIMEOUT #
TIMEOUT=7200 # 2 hourAllow testss
PROGRESS_INTERVAL=300 # 5 minutes
BOSSPID=$$
(
  if [ "${BASH_VERSINFO[0]}" -lt 4 ] ; then
    echo "Setting BASHPID for bash < v4"
    t="/tmp/$$.sh" ; echo 'echo $PPID' > $t
    BASHPID=`bash $t`
    rm $t
  fi
  if [[ "$TRAVIS" = "true" ]] ; then
    echo "Wake travis every $PROGRESS_INTERVAL seconds"
    timeout $TIMEOUT bash -c -- "while true; do sleep $PROGRESS_INTERVAL ; printf '...';done"
  else
    echo "Set timeout to $TIMEOUT seconds."
    sleep $TIMEOUT
  fi
  echo
  echo "Test timed out after $TIMEOUT seconds."
  echo
  killtree $BOSSPID
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

rake reinstall
ruboto setup -y -t $ANDROID_TARGET
source ~/.rubotorc

ruboto emulator -t $ANDROID_TARGET --no-snapshot
> adb_logcat.log

(gem query -q -i -n ^bundler$ >/dev/null) || gem install bundler
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
