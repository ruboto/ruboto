Subject: [ANN] Ruboto 1.5.0 released!

The Ruboto team is pleased to announce the release of Ruboto 1.5.0.

Ruboto (JRuby on Android) is a platform for developing full stand-alone
apps for Android using the Ruby language and libraries.  It includes
support libraries and generators for creating projects, classes, tests,
and more.  The complete APIs of Android, Java, and Ruby are available to
you using the Ruby language.

New in version 1.5.0:

We now have properly working Ruby SSL and HTTPS!  You need jruby-jars
1.7.25 and Android 4.4 or better :)

API Changes:

* Issue #713 Add support for Android 5.1 Lollipop
* Issue #768 Add support for Android 6.0 Marshmallow

Features:

* Issue #791 Update RubotoCore to ActiveRecord 4.2
* Issue #792 Set emulator name in ruboto.yml
* Issue #795 Set emulator device name in ruboto.yml
* Issue #797 Set emulator skin name in ruboto.yml
* Issue #798 ruboto.yml emulator config (donv)
* Issue #805 Add support for the new emulator 2.0

Bugfixes:

* Issue #726 Any reference to net/https throws LoadError for
  org/bouncycastle/bcpkix-jdk15on/1.47/bcpkix-jdk15on-1.47
* Issue #793 Fix OpenSSL
* Issue #796 Adds a setting in "ruboto.yml" for the desired
  dex_heap_size (lucasallan)
* Issue #807 Fix SDK_DOWNLOAD_PAGE link (LucianoPC)

Support:

* Issue #802 java.lang.UnsupportedOperationException: can't load this
  type of class file
* Issue #803 (NoMethodError) undefined method 'current' for
  Java::JavaLang::Thread:Class

Community:

* Issue #666 Set up donations and sponsoring of the Ruboto project

Pull requests:

* Issue #794 Test ssl (donv)
* Issue #812 Set ANDROID_EMULATOR_FORCE_32BIT to fix broken build
  (celeduc)

Internal:

* Issue #775 Release 1.5.0
* Issue #808 Bug fixes (donv)

You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=41


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
