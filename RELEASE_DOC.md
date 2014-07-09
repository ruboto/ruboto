Subject: [ANN] Ruboto 1.1.2 released!

The Ruboto team is pleased to announce the release of Ruboto 1.1.2.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.1.2:

This is a quick release to add support for version 23 of the Android SDK.

Bugfixes:

* Issue #636 ruboto setup failing to install Android
* Issue #637 Fixed match for SDK release versions (daneb)
* Issue #639 Unit test fix (daneb)
* Issue #641 Display progress text during linux package installs

Internal:

* Issue #633 Release 1.1.2 gem

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=34


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
