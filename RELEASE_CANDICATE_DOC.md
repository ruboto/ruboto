Subject: [ANN] Ruboto 1.0.3 release candidate

Hi all!

The Ruboto 1.0.3 release candidate is now available.

This release focuses on stability and introduces a new mechanism for
reducing the footprint of your app using the ruboto.yml config file.  You
can now specify the Ruby compatibility level of your app (1.8/1.9/2.0) and
which parts of the Ruby Standard Library you want to use.  Ruboto will now
strip the parts you don't need, making your app a bit smaller.

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
