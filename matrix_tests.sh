#!/bin/bash -e

for platform in "CURRENT MASTER STANDALONE" ; do
  for target in "15 10" ; do
    if [ "$platform" == "STANDALONE" ] ; then
      $jruby_versions = "1.7.0.dev 1.6.7 1.5.6"
    elif [ "$platform" == "MASTER" ] ; then
      $jruby_versions = "1.7.0.dev"
    elif [ "$platform" == "CURRENT" ] ; then
      $jruby_versions = "1.7.0.dev"
    fi
    for jruby_version in "$jruby_versions" ; do
      export RUBOTO_PLATFORM=$platform
      export ANDROID_TARGET=$target
      export JRUBY_JARS_VERSION=$jruby_version
      ./run_tests.sh
    done
  done
done
