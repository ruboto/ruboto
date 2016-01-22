Subject: [ANN] Ruboto 1.4.1 released!

The Ruboto team is pleased to announce the release of Ruboto 1.4.1.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.4.1:

Bugfixes for the 1.4.0 release.

Features:

* Issue #779 Differentiate the default dex heap size for 32-bit systems
* Issue #780 Update "rake log" to handle output from Android 6.0
* Issue #782 Do not commit the keystore by default
* Issue #789 Add support for JRuby 1.7.24

Bugfixes:

* Issue #783 Don't report changing emulator properties when they are not
  actually changed
* Issue #784 Improve haxm install with/without "-y" and "--upgrade"
  options (donv)
* Issue #785 Setup never finds Platform SDK
* Issue #786 Use $ANDROID_HOME instead of android executable location to
  find platforms (ahills)
* Issue #790 Fix "--update" option for "ruboto setup"

Performance:

* Issue #787 Refresh the benchmark server layout and design

Support:

* Issue #749 Invalid maximum heap size: -Xmx4096M
* Issue #761 JDK 7

Internal:

* Issue #773 Release 1.4.1

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=40


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
