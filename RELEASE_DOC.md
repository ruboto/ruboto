Subject: [ANN] Ruboto 1.1.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.1.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.1.0:

This release adds support for large projects with more than 64K methods
and Ruby stdlib HTTPS/SSL.  HTTPS/SSL using the Android APIs is working as
before.

To use the Ruby stdlib SSL features you need to include JRuby 1.7.13 or
later in your app, and set the Android target to Android 4.1 (api level
android-16) or later.  JRuby 1.7.13 has not been released yet, but you can
use the "jruby-1_7" or "master" branches of JRuby if you want to try it
now.

The large app feature utilises the "multi-dex" option of the Android
tooling, and also requires the target of your project to be set to Android
4.1 (api level android-16) or later.

The SSL feature is still new and will be improved in the coming releases
of Ruboto.  An example is that accessing GitHub by https does not work out
of the box.  This is being tracked as Issue #627 , and we would very much
like contributors on this.

Features:

* Issue #154 Add support for SSL
* Issue #459 openssl jruby error
* Issue #601 Support large projects using multiple dex files
* Issue #605 Easily change the JRuby version with "ruboto <gen|update>
  jruby <version>"
* Issue #606 Allow setting the JRuby version when creating or updating a
  project with "--with-jruby <version>"
* Issue #608 Allow starting the emulator without using a snapshot
* Issue #610 Screen Scraper alongside Repository XML (daneb)
* Issue #611 Allow setting flags when starting a RubotoActivity
* Issue #623 If the emulator starts, but does not respond, retry without
  loading a snapshot
* Issue #624 Allow setting the Android API target level for "ruboto
  update app"

Bugfixes:

* Issue #342 require 'net/https' makes the app crash
* Issue #586 ruboto doesn't recover from failed adb devices command
* Issue #596 Detecting of dependencies misses open-uri due to dash in
  file name
* Issue #597 Auto dependencies should not store application source
* Issue #598 Ruboto-Core Package file is invalid
* Issue #604 Use the correct archive name when downloading Android SDK
  components
* Issue #612 Ruboto setup on Failing on Mac OS X
* Issue #618 Intelhaxm - Mac OS X more generic (daneb)
* Issue #622 Intelhaxm (daneb)

Performance:

* Issue #599 Speed up displaying Options Menu
* Issue #616 Speed up Activity#setContentView

Support:

* Issue #591 Problem completing the "gosu_android game" tutorial

Community:

* Issue #567 How can I help? (Noeyfan)
* Issue #570 How can I help? (aripoya)
* Issue #571 How can I help? (cjbcross)
* Issue #602 How can I help? (yamishi13)
* Issue #603 How can I help? (daneb)

Pull requests:

* Issue #588 Wait for valid device before installing (bootstraponline)
* Issue #609 Scraping of Android SDK for Latest Version (daneb)

Other:

* Issue #607 Remove the deprecated "ruboto update ruboto" command

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=19


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
