Subject: [ANN] Ruboto 1.0.1 released!

The Ruboto team is pleased to announce the release of Ruboto 1.0.1.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.0.1:

This release focuses on bug fixes and documentation.

Features:

* Issue #546 Better stack traces using "jruby.rewrite.java.trace" = "true"
* Issue #548 Allow using snapshot versions of jruby-jars

Bugfixes:

* Issue #505 Trigger rebuild of the package if non-ruby source has changed
  in the "src" directory
* Issue #507 Undefined method `__ruby_object' when implementing a Java
  interface
* Issue #537 Generated BroadcastReceiver has incorrect number of argument
  for Log.e
* Issue #541 Gem errors with activerecord-jdbc-sqlite3
* Issue #545 JRuby use of javax.annotation.processing breaks use of ARJDBC
* Issue #554 Better error message when trying to run an emulator for a
  target that is not installed
* Issue #556 "ruboto emulator" ignores HAXM installation on Windows

Documentation:

* Issue #532 Environment setup for windows
* Issue #538 Complete the "What is Ruboto?" WIKI article
* Issue #553 The number of stars for the Ruboto project has disappeared
  from the ruboto.org front page
* Issue #560 Add a tutorial for detecting incoming phone calls

Support:

* Issue #480 Could not locate Gemfile
* Issue #549 How can I view output?
* Issue #551 rake install start problem on windows
* Issue #552 Problem with rake install start on windows
* Issue #555 Ruboto command not found after installation

Community:

* Issue #531 How can I help?

Pull requests:

* Issue #550 Fix Log import

Internal:

* Issue #513 Refactor to generate special
  onCreate/onDestroy/onBind/onStartCommand instead of hard coding
* Issue #559 Remove redundant script file reference in
  InheritingBroadcastReceiver

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=31


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
