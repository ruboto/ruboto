Subject: [ANN] Ruboto 1.2.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.2.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.2.0:

In this release we add support for the Android L preview and the ART
runtime.  We also specify accessing the "R" class without specifying a
package to refer to the local package "R" class instead of "android.R".

Features:

* Issue #523 Support for ART
* Issue #645 Make ::R refer to $package.R instead of android.R
* Issue #652 Set a layout attribute by name even if it is not a JavaBean
  attribute (like margins and padding).
* Issue #654 Access android.R inner classes like android.R.id and
  android.R.attr directly
* Issue #656 Add support for Android L developer preview

Bugfixes:

* Issue #643 Stale code in widget.rb lists
* Issue #648 Service code is broken when trying to use RubotoService
  directly
* Issue #667 Ruboto app generation with option --with-jruby 1.7.14 not
  working properly
* Issue #671 RubotoService fails to start on Android L
* Issue #672 Problem with ruboto setup
* Issue #674 travis build fails with JRuby 1.7.16

Support:

* Issue #573 How can I load Ruboto Core Dynamically in Runtime?

Rejected:

* Issue #646 Make ANT quiet by default, enabling verbose and trace
  output with the -v and -t rake options

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=35


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
