Subject: [ANN] Ruboto 1.6.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.6.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.6.0:

In this release we add support for Android 7.0 and 7.1 "Nougat" and update
the Android SDK to level 25.

API Changes:

* Issue #816 Set default api level for new apps to 19 (Android 4.4
  KitKat)
* Issue #821 Update to Android SDK Tools 25
* Issue #826 Rename 'assert_matches' to 'assert_match' for Minitest
  compatibility

Features:

* Issue #815 Add support for Android 7 Nougat
* Issue #817 Add support for Android 7.1
* Issue #819 Add support for concurrent-ruby gem
* Issue #820 Reload scripts with large stack during 'rake boing'

Bugfixes:

* Issue #813 ArgumentError creating new emulator image (AVD)
* Issue #818 Error when creating a new emulator image for an app with
  empty ruboto.yml

Support:

* Issue #809 [Solved] JRuby 1.7.22 and Crosswalk issue (multidex)
  Verification error in java.io.File[]
  org.jruby.util.JRubyFile.listRoots()
* Issue #822 How well does Ruboto work with Shoes 4?

Internal:

* Issue #828 More test parts (donv)
* Issue #829 Use the new authenticated protocol to manage emulators

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=42


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
