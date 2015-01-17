#!/bin/bash -el

echo "Starting tests..."

# BEGIN TIMEOUT #
TIMEOUT=3000 # 50 minutes
BOSSPID=$$
(
  sleep $TIMEOUT
  echo
  echo "Test timed out after $TIMEOUT seconds."
  echo
  kill -9 -$BOSSPID
  echo
  echo Emulator log:
  echo
  cat adb_logcat.log
  echo
  echo "Test timed out after $TIMEOUT seconds."
)&
TIMERPID=$!
echo "PIDs: Boss: $BOSSPID, Timer: $TIMERPID"

trap "kill -9 $TIMERPID" EXIT
# END TIMEOUT #

if [ ! $(command -v ant) ] ; then
  if [ -e /etc/profile.d/ant.sh ] ; then
    . /etc/profile.d/ant.sh
  else
    echo Apache ANT is missing!
    exit 2
  fi
fi
ant -version

(gem query -q -i bundler >/dev/null) || gem install bundler
bundle install

rake clean
set +e
rake test $*
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
