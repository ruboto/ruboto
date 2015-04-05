Subject: [ANN] Ruboto 1.3.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.3.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.3.0:

It's been a long time since the last release.  We have had some problems
getting the test matrix green at https://travis-ci.org/ruboto/ruboto and
as there are still some combinations failing, we need help to fix them.
If you have experience debugging on Android, please contribute.

In the meantime, we have added support for JRuby up to 1.7.19 and Android
up to 5.1.  There are still some bugs to sort out, but we are getting
there  :)  Testing with JRuby 9000 has begun, but is currently failing.

A new feature is the running of "src/environment.rb" if it is present
right after JRuby initialization.  This enables loading of gems and code
common across activities, broadcast receivers, and services.

Use of Bundler has improved to allow gems that duplicate files in Ruby
Stdlib like JSON, and allow local gems using the "path" option in the
Gemfile.  Support for ActiveRecord has been updated to 4.1.

Finally we have updated the homepage and wiki with a few changes.

Thanks to all who have contributed!

API Changes:

* Issue #689 Add support for Android 5 Lollipop
* Issue #690 Update to JRuby 1.7.19

Features:

* Issue #647 Run environment.rb after JRuby initialization
* Issue #696 Add support for local gems
* Issue #699 Add support for ActiveRecord 4 and the thread_safe gem
* Issue #701 Add support for ActiveRecord 4.1

Bugfixes:

* Issue #627 Fix HTTPS access to GitHub
* Issue #678 Update setup.rb (sardaukar)
* Issue #679 Fix for finding the Platform SDK on OS X when using
  homebrew
* Issue #681 Warning after ruboto setup
* Issue #700 Allow non-utf8 output in "rake log"
* Issue #702 Exception running "ruboto setup -t 19 -y" on OS X 10.10
* Issue #706 Avoid duplicate files in bundle vs stdlib
* Issue #707 Choose the latest build-tools in "ruboto setup"

Documentation:

* Issue #676 Modification to Wiki for Mac OS Guide
* Issue #677 Ruboto Main Page - misinformation?

Support:

* Issue #590 Cannot open apk in emulator
* Issue #680 Android SDK Command dx   : Not found
* Issue #682 ruboto gen app only works if sdk api level 15 installed

Community:

* Issue #578 How can I help? (jaunesarmiento)
* Issue #581 How can I help? (bobquest33)

Internal:

* Issue #709 Remove swap manipulation and sudo (BanzaiMan)
* Issue #711 Test JRuby 1.7.20.dev, 1.7.19, 1.7.15, and 1.7.13. (donv)

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=36


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
