Subject: [ANN] Ruboto 1.3.0 release candidate

Hi all!

The Ruboto 1.3.0 release candidate is now available.

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
