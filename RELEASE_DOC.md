Subject: [ANN] Ruboto 1.1.1 released!

The Ruboto team is pleased to announce the release of Ruboto 1.1.1.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.1.1:

This release introduces a significant speedup of all UI actions by only
overriding those Java methods actually implemented in Ruby code.  There
are also some bug fixes and improvements to the SSL and big-app features.

Features:

* Issue #619 Automatically switch multi-dex build on and off
* Issue #625 Avoid storing extra dex files in assets since they are not
  source.
* Issue #628 Set tmpdir location

Performance:

* Issue #574 Will Android 4.4 ART influence Ruboto APP?
* Issue #629 Disable RubotoActivity methods that are not in use

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=33


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
