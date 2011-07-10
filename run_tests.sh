#!/bin/bash -e

if [ -e /usr/local/jruby ] ; then
  export JRUBY_HOME=/usr/local/jruby
  export PATH=$JRUBY_HOME/bin:$PATH
elif [ -e /Library/Frameworks/JRuby.framework/Versions/Current ] ; then
  export JRUBY_HOME=/Library/Frameworks/JRuby.framework/Versions/Current
  export PATH=$JRUBY_HOME/bin:$PATH
fi
unset GEM_HOME
bundle install --system
if [ "$JRUBY_JARS_VERSION" != "" ] ; then
  gem uninstall jruby-jars --all -v "!=$JRUBY_JARS_VERSION" && gem install -v "$JRUBY_JARS_VERSION" jruby-jars
fi
rake --trace test
