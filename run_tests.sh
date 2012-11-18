#!/bin/bash -el

# BEGIN TIMEOUT #
TIMEOUT=14400 # 4 hours
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

if [ ! $(command -v ant) ] ; then
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
  if [ ! $(command -v rvm) ] ; then
    echo RVM is missing!
    exit 2
  fi
  rvm --version
  unset JRUBY_HOME
  rvm install $RUBY_IMPL
  rvm use $RUBY_IMPL
  echo -n
fi

export NOEXEC=0
rake clean
rake test $*
