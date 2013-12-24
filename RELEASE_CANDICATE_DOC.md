Subject: [ANN] Ruboto 1.0.0 release candidate

Hi all!

The Ruboto 1.0.0 release candidate is now available.

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
