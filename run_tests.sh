#!/bin/bash -e

# BEGIN TIMEOUT #
TIMEOUT="2400"
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

if [ -e /usr/local/jruby ] ; then
  export JRUBY_HOME=/usr/local/jruby
  CUSTOM_JRUBY_SET=yes
elif [ -e /Library/Frameworks/JRuby.framework/Versions/Current ] ; then
  export JRUBY_HOME=/Library/Frameworks/JRuby.framework/Versions/Current
  CUSTOM_JRUBY_SET=yes
fi

if [ "$CUSTOM_JRUBY_SET" == "yes" ] ; then
  export PATH=$JRUBY_HOME/bin:$JRUBY_HOME/lib/ruby/gems/*/bin:$PATH
  jruby --version
fi

rm -rf tmp/RubotoCore
rake test --trace

# BEGIN TIMEOUT #
# kill -9 $TIMERPID
# END TIMEOUT #
