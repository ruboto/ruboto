Subject: [ANN] Ruboto 1.1.0 release candidate

Hi all!

The Ruboto 1.1.0 release candidate is now available.

This release adds support for large projects with more than 64K Java
methods and Ruby stdlib HTTPS/SSL.  HTTPS/SSL using the Android APIs is
working as before.

To use the Ruby stdlib SSL features you need to include JRuby 1.7.13 or
later in your app, and set the Android target to Android 4.1 (api level
android-16) or later.  JRuby 1.7.13 has not been released yet, but you can
use the "jruby-1_7" or "master" branches of JRuby if you want to try it
now.

The large app feature utilises the "multi-dex" option of the Android
tooling, and also requires the target of your project to be set to Android
4.1 (api level android-16) or later.

The SSL feature is still new and will be improved in the coming releases
of Ruboto.  An example is that accessing GitHub by https does not work out
of the box.  This is being tracked as Issue #627 , and we would very much
like contributors on this.

As always we need your help and feedback to ensure the quality of the release.  Please install the release candidate using

    [sudo] gem install ruboto --pre

and test your apps after updating with

    ruboto update app

If you have an app released for public consumption, please let us know.  Our developer program seeks to help developers getting started using Ruboto, and ensure good quality across Ruboto releases.  Currently we are supporting the apps listed here:

    https://github.com/ruboto/ruboto/wiki/Promoted-apps

If you are just starting with Ruboto, but still want to contribute, please select and complete one of the tutorials and mark it with the version of Ruboto you used.

    https://github.com/ruboto/ruboto/wiki/Tutorials-and-examples

If you find a bug or have a suggestion, please file an issue in the issue tracker:

    https://github.com/ruboto/ruboto/issues

--
The Ruboto Team
http://ruboto.org/
