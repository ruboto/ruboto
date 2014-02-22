Subject: [ANN] Ruboto 1.0.2 released!

The Ruboto team is pleased to announce the release of Ruboto 1.0.2.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.0.2:

This releases updates to JRuby 1.7.10 and improves installation with
automated setup of Apache ANT on Windows and Linux.

Features:

* Issue #447 Use "ruboto setup" to flag and install ant
* Issue #564 Update to JRuby 1.7.10

Bugfixes:

* Issue #525 Quick Start : "Unfortunately, Browser has stopped"
* Issue #565 Odd behaviour when changing orientation with Fragments
* Issue #575 Gemfile.lock contains references to gems that are not part
  of the dependencies

Documentation:

* Issue #568 Error with tutorial on "Example: Open a web page"

Community:

* Issue #533 How can I help? (di3z )
* Issue #562 How can I help? (lucasallan)
* Issue #563 How can I help? (pedroandrade)
* Issue #572 How can I help? (iamrahulroy)

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=27


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
