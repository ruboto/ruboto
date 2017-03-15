Subject: [ANN] Ruboto 1.6.1 released!

The Ruboto team is pleased to announce the release of Ruboto 1.6.1.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.6.1:

This is a maintenance release following changes in the Android tooling.

Features:

* Issue #836 Add JRuby jars to new projects by default

Bugfixes:

* Issue #806 Ruboto setup fails: get_android_sdk_version
* Issue #811 Package installer error
* Issue #824 undefined method '[]' for nil:NilClass (NoMethodError)

Internal:

* Issue #827 Assume multi-dex on first build

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=43


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
