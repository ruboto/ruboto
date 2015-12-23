Subject: [ANN] Ruboto 1.4.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.4.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.4.0:

This release adds support for JRuby 1.7.22 and improves the installation
of HAXM.  `ruboto setup --update` will now update an existing HAXM
installation if a new version is available for download.

Support for Android 2.3 has been dropped, and Android 4.1 is now the
default api level when creating new apps.

API Changes:

* Issue #687 Drop support for Android 2.3 api level 10
* Issue #688 Set Android 4.1 api level 16 as default api level for new
  apps
* Issue #770 Support jruby 1.7.22 (donv)

Features:

* Issue #722 Start emulator without skin for "ruboto emulator"
* Issue #756 Allow "ruboto setup --update" to update HAXM if a new
  version is available

Bugfixes:

* Issue #634 Can't add jar files to proyect. Can't start the proyect
  with jars added
* Issue #638 Extra installs to build on Ubuntu 64 bit
* Issue #655 "--with-jruby" seems to do its job, but then I still need
  to download and install Ruboto Core on device
* Issue #663 Minimal Gosu code fails.
* Issue #664 Bundler can't see personal gems/Locally installed gems do
  not get put on projects(only global).
* Issue #669 Keep on restarting new emulator
* Issue #686 Can't run on Real device with Android 5.0
* Issue #703 The HAXM installer for OS X has changed name
* Issue #712 can´t install ruboto
* Issue #716 New App with no custom code terminates directly after start
  (java.lang.NoSuchMethodException: makeDexElements).
* Issue #717 ruboto setup -y - FATAL -- : undefined method 'slice' for
  nil:NilClass
* Issue #742 Accept Android plataform tools rc in setup
* Issue #747 Running the emulator often hangs when run without
  "--no-snapshot"
* Issue #759 "ruboto gen jruby" should install jruby-jars ~>1.7
* Issue #765 'rake boing' fails for multiple updated files

Support:

* Issue #670 emulator
* Issue #736 rake install error
* Issue #739 Game Frameworks?
* Issue #752 can't install ruboto with ruby gems in windows 10.

Community:

* Issue #766 Reduce noise on #ruboto channel from travis
* Issue #771 How can I help? (ChaosCat)

Internal:

* Issue #757 Release 1.4.0
* Issue #767 TypeError: can't convert nil into String when running
  Ruboto tests
* Issue #769 Fetch jruby-jars snapshots from http://ci.jruby.org/ for
  testing
* Issue #772 Db haxm dark (daneb)

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=39


Installation:

To use Ruboto, you need to install a Ruby implementation.  Then do
(possibly as root/administrator)

    gem install ruboto
    ruboto setup -y

To create a project do

    ruboto gen app --package <your.package.name>
    cd <project directory>
    ruboto setup -y

To run an emulator for your project

    cd <project directory>
    ruboto emulator

To run your project

    cd <project directory>
    rake install start

You can find an introductory tutorial at
https://github.com/ruboto/ruboto/wiki

If you have any problems or questions, come see us at http://ruboto.org/

Enjoy!


--
The Ruboto Team
http://ruboto.org/
