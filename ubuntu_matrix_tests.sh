#!/usr/bin/env bash

vagrant up ubuntu
vagrant ssh ubuntu -c "mkdir -p ruboto ; rsync -acPuv --exclude adb_logcat.log --exclude /tmp /vagrant/* ruboto/ ; cd ruboto ; ./matrix_tests.sh"
