#!/bin/bash -e

# BEGIN TIMEOUT #
TIMEOUT="3700"
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

gem query -i -n bundler || gem install bundler
bundle install

if [ "$RUBOTO_PLATFORM" == "MASTER" ] ; then
  echo "Using RubotoCore built from master"
  rake platform:clean platform:debug
elif [ "$RUBOTO_PLATFORM" == "STANDALONE" ] ; then
  echo "Standalone: Including JRuby in the app"
  rake platform:clean
else
  echo "Using current release of RubotoCore"
  if [ ! -e "tmp/RubotoCore/bin" ] ; then
    rake platform:debug
  fi
  cd tmp/RubotoCore/bin
  if [ RubotoCore-release.apk -nt RubotoCore-debug.apk -o RubotoCore-release.apk -ot RubotoCore-debug.apk ] ; then
    wget --no-check-certificate https://github.com/downloads/ruboto/ruboto/RubotoCore-release.apk
    cp -a RubotoCore-release.apk RubotoCore-debug.apk
  fi
  cd -
  rake platform:uninstall
fi

rake test --trace

# BEGIN TIMEOUT #
# kill -9 $TIMERPID
# END TIMEOUT #
