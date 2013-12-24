Subject: [ANN] Ruboto 1.0.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.0.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.0.0:

The main motivation for the 1.0 release is to announce that Ruboto is
ready for general consumption!

* All important parts of the Android API are available.
* The API has stabilised.
* Performance is reasonable. (Best case startup 4 seconds or less).
* Home page/Wiki/Tutorials and other docs are of high enough quality that
new developers have a low threshold to get going, and more advanced
developers can find how to do more advanced apps.

Notable features this release is RubyGems support for the "dalvik"
platform and support for using Android utility projects.  This means you
can release gems for dalvik only and consume in-house or third-party
utility projects.

Features:

* Issue #75 Faster startup
* Issue #392 Establish a specialized RubyGems platform for JRuby on
  Android
* Issue #524 Use "ruboto emulator" to setup HAXM
* Issue #530 Shift all layout parameters into :layout = {} and remove the
  need for "=" in setting instance variables
* Issue #544 Add support for using utility projects

Bugfixes:

* Issue #431 Error running Ruboto test suites
* Issue #483 The Tutorial: adding a startup splash builds but crashes
  starting in the emulator
* Issue #534 ruboto emulator -t does not show emulator window though it
  says Emulator started OK
* Issue #542 please install the jdbcsqlite3 adapter

Support:

* Issue #520 ruboto setup - "Android SDK command adb : Not found"
* Issue #539 "rake install start" returns "rake aborted! No such file or
  directory - adb"

Documentation:

* Issue #506 Add barcode scanning example
* Issue #528 Fix formatting errors in the RELEASE_DOC
* Issue #535 Mac kernel freezes when ruboto emulator start under MacOS
  10.9 with Virtualbox 4.3.x installed.

Pull requests:

* Issue #527 Add weight to widget.rb
* Issue #536 Update emulator.rb (Fix no emulator window shows in MacOS
  10.9 with Virtualbox 4.3, when $DISPLAY variable is empty)

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=17


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
