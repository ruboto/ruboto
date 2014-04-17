Subject: [ANN] Ruboto 1.0.3 released!

The Ruboto team is pleased to announce the release of Ruboto 1.0.3.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.0.3:

This release focuses on stability and introduces a new mechanism for
reducing the footprint of your app using the ruboto.yml config file.  You
can now specify the Ruby compatibility level of your app (1.8/1.9/2.0) and
which parts of the Ruby Standard Library you want to use.  Ruboto will now
strip the parts you don't need, making your app a bit smaller.

Features:

* Issue #418 Dynamic Ruboto runtime sizing and inclusion
* Issue #576 Make Android 4.0 the default target.
* Issue #592 Update to JRuby 1.7.12

Bugfixes:

* Issue #529 rake install start fails on windows
* Issue #566 ruboto emulator -t android-19 failed
* Issue #580 Ruboto setup fails if the path configuration script doesn't
  exist
* Issue #582 JRuby 9000 tests fail
* Issue #583 'ruboto setup' crashes when config file does not exist.
* Issue #585 rake install start does not power up app in Android 4.4
  Kitkat emulator and sleeps at build successful
* Issue #587 warning breaks is_installed?

Support:

* Issue #579 Android platform SDK for android-10 not found (v1.0.2)

Internal:

* Issue #577 Domain expired

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=28


Installation:

To use Ruboto, you need to install a Ruby implementation.  Then do
(possibly as root/administrator)

    gem install ruboto
    ruboto setup

To create a project do

    ruboto gen app --package <your.package.name>
    cd <project directory>
    ruboto setup

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
