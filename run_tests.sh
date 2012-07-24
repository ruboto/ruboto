#!/bin/bash -e

# BEGIN TIMEOUT #
TIMEOUT=7200
BOSSPID=$$
(
  sleep $TIMEOUT
  echo
  echo "Test timed out after $TIMEOUT seconds."
  echo
  kill -9 $BOSSPID
)&
TIMERPID=$!
echo "PIDs: Boss: $BOSSPID, Timer: $TIMERPID"

trap "echo killing timer ; kill -9 $TIMERPID" EXIT
# END TIMEOUT #

if which ant ; then
  echo -n
else
  if [ -e /etc/profile.d/ant.sh ] ; then
    . /etc/profile.d/ant.sh
  else
    echo Apache ANT is missing!
    exit 2
  fi
fi
ant -version

if [ "$RUBY_IMPL" != "" ] ; then
  if [ -e /etc/profile.d/rvm.sh ] ; then
    . /etc/profile.d/rvm.sh
  fi
  if !(which rvm) ; then
    echo RVM is missing!
    exit 2
  fi
  rvm --version
  rvm install $RUBY_IMPL
  rvm use $RUBY_IMPL
  echo -n
fi

rake platform:clean
rake test --trace
