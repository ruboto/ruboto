Subject: [ANN] Ruboto 1.3.1 released!

The Ruboto team is pleased to announce the release of Ruboto 1.3.1.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.3.1:

Bugfixes for the 1.3.0 release.

API Changes:

* Issue #733 Remove support for RubotoCore 0.4.7

Features:

* Issue #720 Install 64 bit system images for Android 5
* Issue #721 Create and start emulator with 64bit system image for
  Android 5
* Issue #741 Make setup accept build tools rc (danielpassos)

Bugfixes:

* Issue #635 Gosu example is not working
* Issue #668 Android API version above 15 not working
* Issue #715 ruboto setup -y: FATAL -- : undefined method '[]' for
  nil:NilClass (NoMethodError)
* Issue #718 Haxm 10.9 daneb (daneb)
* Issue #728 Fix haxm installation for MacOS  (phantomwhale)
* Issue #729 (ArgumentError) unable to create proxy class for class
  java.util.HashMap : null
* Issue #734 ruboto setup problem

Performance:

* Issue #642 generate java methods in the build process only for
  implemented ruby met... (tek)

Support:

* Issue #631 ruby version problem
* Issue #719 Webview addJavaScriptInterface
* Issue #731 Quick Start Example
* Issue #743 Help with LibGDX on Ruboto
* Issue #746 ruboto setup - Java heap space
  (Java::JavaLang::OutOfMemoryError)

Community:

* Issue #589 How can I help? (devaroop)
* Issue #640 How can I help? (sg552)
* Issue #651 How can I help? (arantessergio)
* Issue #659 How can I help?
* Issue #662 How can I help? (aripoya)
* Issue #665 How can I help?
* Issue #683 How can I help?
* Issue #684 How can I help?
* Issue #685 How can I help?
* Issue #694 How can I help?
* Issue #704 How can I help?
* Issue #725 How can I help?
* Issue #730 How can I help?

Pull requests:

* Issue #740 rake log task detects activity start on lollipop (gfowley)

Internal:

* Issue #724 Get travis-ci GREEN! (donv)

Rejected:

* Issue #367 Remove support for running in Ruby 1.8 mode

Other:

* Issue #692 --with-jruby argument not working correctly

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=38


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
