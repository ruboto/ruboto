Ruboto Core
=============

Ruby on Android.

Installation
-------

    gem install ruboto-core

Getting Started
---------------

Before you use Ruboto, you should do the following things:

* Install the JDK if it's not on your system already
* Install [jruby](http://jruby.org/) if you don't already have it.JRuby also has a [very easy install process](http://jruby.org/#2), or you can use [rvm](http://rvm.beginrescueend.com/)
* Install [the Android SDK](http://developer.android.com/sdk/index.html)
* Add the sdk's `tools/` directory to your `$PATH`

General Information
------------------

The Rakefile assumes that you are in the root directory of your app, as do all commands of the `ruboto` command line utility, other than `ruboto gen app`.

The Rakefile requires you to run it through JRuby's rake. 

Features
-------

* [Application generator](#application_generator) (like the rails application generator)
* [Class generator](#class_generator) to generate additional Activities, BroadcastReceivers, Services, etc.
* [Packaging task](#packaging_task) to generate an apk file
* [Deployment task](#deployment_task) to deploy a generated package to an emulator or connected device
* Update path when ruboto is updated, either by "gem update" or "rake ruboto:update" (not decided, yet)

<span name="application_generator">
### Application generator
</span>

    ruboto gen app --package com.yourdomain.whatever --path path/to/where/you/want/the/app --name NameOfApp --target android-version --activity MainActivityName
Target should be something like `android-8` (8 is Froyo)

<span name="class_generator">
### Class generator
</span>

    ruboto gen class ClassName --name YourObjectName
Ex:
    ruboto gen class BroadcastReceiver --name AwesomenessReceiver

<span name="packaging_task">
### Packaging task
</span>

This will generate an apk file.

    rake

<span name="deployment_task">
### Deployment task
</span>

When you're ready to post your app to the Market, you need to do a few things.

First, you'll need to generate a key to sign the app with using `keytool` if you do not already have one. If you're ok with accepting some sane defaults, you can use
    ruboto gen key --alias alias_for_your_key
with an optional flag `--keystore /path/to/keystore.keystore`, which defaults to `~/.android/production.keystore`. It will ask for a password for the keystore and one for the key itself. Make sure that you remember those two passwords, as well as the alias for the key. 

Also make sure to keep your key backed up (if you lose it, you won't be able to release updates to your app that can install right over the old versions), but secure.

Once you have your key, use the `rake publish` task to generate a market-ready `.apk` file. You will need the `RUBOTO_KEYSTORE` and `RUBOTO_KEY_ALIAS` environment variables set to the path to the keystore and the alias for the key, respectively. So either run
    RUBOTO_KEYSTORE=~/.android/production.keystore RUBOTO_KEY_ALIAS=foo rake publish
or set those environment variables in your `~/.bashrc` or similar file and just run
    rake publish
Now get that `.apk` to the market!

### Updating Ruboto

Not implemented, yet.


Contributing
------------

Want to contribute? Great! Meet us on #ruboto on irc.freenode.net, fork the project and start coding!

### Building the gem

    rake gem


Getting Help
------------

* You'll need to be pretty familiar with the Android API. The [Developer Guide](http://developer.android.com/guide/index.html) and [Reference](http://developer.android.com/reference/packages.html) are very useful. 
* There is further documentation at the [wiki](http://github.com/ruboto/ruboto-core/wiki)
* If you have bugs or feature requests, [open an issue on GitHub](http://github.com/ruboto/ruboto-core/issues)
* You can ask questions in #ruboto on irc.freenode.net and on the [mailing list](http://groups.google.com/groups/ruboto)

Tips & Tricks
-------------

### Emulators

If you're doing a lot of Android development, you'll probably find yourself typing `emulator -avd name_of_emulator` a lot to open emulators. It can be convenient to alias these to shorter commands.

For example, in your `~/.bashrc`, `~/.zshrc`, or similar file, you might put
    alias eclair="emulator -avd eclair"
    alias froyo="emulator -avd froyo"
If you have an "eclair" emulator that runs Android 2.1 and a "froyo" one that runs Android 2.2.
