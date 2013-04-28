Ruboto
=============

Ruby on Android.

Installation
-------

    $ gem install ruboto

Getting Started
---------------

Before you use Ruboto, you should do the following things:

* Install the JDK if it's not on your system already
* Install [jruby](http://jruby.org/) if you don't already have it. JRuby has a [very easy install process](http://jruby.org/#2), or you can use [rvm](https://rvm.io/rvm/install/)
* Install [the Android SDK](http://developer.android.com/sdk/index.html)
* Add the sdk to `$ANDROID_HOME` as an absolute path (Java does not expand tildes `~`)
* Add the sdk's `tools/` and `platform-tools/` directory to your `$PATH`
* Generate an [Emulator](http://developer.android.com/guide/developing/tools/emulator.html) image unless you want to develop using your phone.

General Information
------------------

The Rakefile assumes that you are in the root directory of your app, as do all commands of the `ruboto` command line utility, other than `ruboto gen app`.

The Rakefile requires you to run it through JRuby's rake.

Command-line Tools
-------

* [Application generator](#application_generator) (like the rails application generator)
* [Class generator](#class_generator) to generate additional Activities, BroadcastReceivers, Services, etc.
* [Callback generator](#class_generator) to generate specific subclasses to open up access (callbacks) for various portions of the Android API.
* [Packaging task](#packaging_task) to generate an apk file
* [Deployment task](#deployment_task) to deploy a generated package to an emulator or connected device
* [Develop without having to compile to try every change](#update_scripts)


<a name="application_generator"></a>
### Application generator

    $ ruboto gen app --package com.yourdomain.whatever --path path/to/where/you/want/the/app --name NameOfApp --target android-version --min-sdk another-android-version --activity MainActivityName
Version values must be specified using'android-' and the sdk level number (e.g., android-8 is froyo).

<a name="class_generator"></a>
### Class generator

Generates a Java class (Activity, Service, or BroadcastReceiver) associated with a specific ruboto script.  The generator also generates a corresponding test script.

    $ ruboto gen class ClassName --name YourObjectName
Ex:
    $ ruboto gen class BroadcastReceiver --name AwesomenessReceiver

<a name="callback_generator"></a>
### Callback generator

You can subclass any part of the Android API to pass control over to a script when the specified methods are called. You can also create classes that implement a single Android interface to pass control over to ruboto.

Starting with Ruboto 0.6.0 there are easy ways to do this within your scripts. The new way of generating interfaces and subclasses is described in the wiki [Generating classes for callbacks](https://github.com/ruboto/ruboto/wiki/Generating-classes-for-callbacks)._

<a name="packaging_task"></a>
### Packaging task

This will generate an apk file.

    $ rake

To generate an apk and install it to a connected device (or emulator) all in one go, run

    $ rake install

<a name="deployment_task"></a>
### Deployment task

When you're ready to post your app to the Market, you need to do a few things.

First, you'll need to generate a key to sign the app with using `keytool` if you do not already have one. If you're ok with accepting some sane defaults, you can use
    $ ruboto gen key --alias alias_for_your_key
with an optional flag `--keystore /path/to/keystore.keystore`, which defaults to `~/.android/production.keystore`. It will ask for a password for the keystore and one for the key itself. Make sure that you remember those two passwords, as well as the alias for the key.

Also make sure to keep your key backed up (if you lose it, you won't be able to release updates to your app that can install right over the old versions), but secure.

Once you have your key, use the `rake publish` task to generate a market-ready `.apk` file. You will need the `RUBOTO_KEYSTORE` and `RUBOTO_KEY_ALIAS` environment variables set to the path to the keystore and the alias for the key, respectively. So either run
    $ RUBOTO_KEYSTORE=~/.android/production.keystore RUBOTO_KEY_ALIAS=foo rake publish
or set those environment variables in your `~/.bashrc` or similar file and just run
    $ rake publish
Now get that `.apk` to the market!

<a name="update_scripts"></a>
### Updating Your Scripts on a Device

With traditional Android development, you have to recompile your app and reinstall it on your test device/emulator every time you make a change. That's slow and annoying.

Luckily, with Ruboto, most of your changes are in the scripts, not in the compiles Java files. So if your changes are Ruby-only, you can just run

    $ rake update_scripts

to have it copy the current version of your scripts to your device.

Sorry if this takes away your excuse to have sword fights:

![XKCD Code's Compiling](http://imgs.xkcd.com/comics/compiling.png)

Caveats:

This only works if your changes are all Ruby. If you have Java changes (which would generally just mean generating new classes) or changes to the xml, you will need to recompile your script.

Also, you need root access to your device for this to work, as it needs to write to directories that are read-only otherwise. The easiest solution is to test on an emulator, but you can also root your phone.

### Updating Ruboto's Files

You can update various portions of your generated Ruboto app through the ruboto command:

* JRuby:

1) If a new version of JRuby is released, you should update your gem (e.g., sudo gem update jruby-jars).

2) From the root directory of your app:

    $ ruboto update jruby

* The ruboto.rb script:

1) From the root directory of your app:

    $ ruboto update ruboto

* The core classes (e.g., RubotoActivity):

1) These classes are generated on your machine based on the SDKs (min and target) specified when you 'gen app' (stored in the AndroidManifest.xml)

2) You many want to regenerate them if a new version of the SDK is released, if you change your targets, or if you want more control over the callbacks you receive.

3) From the root directory of your app:

    $ ruboto gen core Activity --method_base all-on-or-none --method_include specific-methods-to-include --method_include specific-methods-to-exclude

4) The generator will load up the SDK information and find the specified methods. The generator will abort around methods that were added or deprecated based on the SDK levels. You can either use method_exclude to remove methods individually or add '--force exclude' to remove the all. You can also us '--force include' to create them anyway (added methods are created without calling super to avoid crashing on legacy hardware).

Scripts
-------

The main thing Ruboto offers you is the ability to write Ruby scripts to define the behavior of Activities, BroadcastReceievers, and Services. (Eventually it'll be every class. It's setup such that adding in more classes should be trivial.)

Here's how it works:

First of all, your scripts are found in `src/` and the script name is the same as the name of your class, only under_scored instead of CamelCased. Android classes have all of these methods that get called in certain situations. `Activity.onDestroy()` gets called when the activity gets killed, for example. Save weird cases (like the "launching" methods that need to setup JRuby), to script the method onFooBar, you call the Ruby method on_foo_bar on the Android object. That was really abstract, so here's an example.

You generate an app with the option `--activity FooActivity`, which means that ruboto will generate a FooActivity for you. So you open `src/foo_activity.rb` in your favorite text editor. If you want an activity that does nothing but Log when it gets launched and when it gets destroyed (in the onCreate and onPause methods). You want your script to look like this:

    require 'ruboto/activity' #scripts will not work without doing this

    class FooActivity
      include Ruboto::Activity
      def onCreate(bundle)
        Log.v 'MYAPPNAME', 'onCreate got called!'
      end

      def onPause
        Log.v 'MYAPPNAME', 'onPause got called!'
      end
    end

The arguments passed to the methods are the same as the arguments that the java methods take. Consult the Android documentation.

Activities also have some special methods defined to make things easier. The easiest way to get an idea of what they are is looking over the [demo scripts](http://github.com/ruboto/ruboto-irb/tree/master/assets/demo-scripts/). You can also read the [ruboto.rb file](http://github.com/ruboto/ruboto-irb/blob/master/src/ruboto.rb) where everything is defined.

Testing
-------

For each generated class, a ruby test script is created in the test/src directory.
For example if you generate a RubotoSampleAppActivity a file test/src/ruboto_sample_app_activity_test.rb
file is created containing a sample test script:

    activity Java::org.ruboto.sample_app.RubotoSampleAppActivity

    setup do |activity|
      start = Time.now
      loop do
        @text_view = activity.findViewById(42)
        break if @text_view || (Time.now - start > 60)
        sleep 1
      end
      assert @text_view
    end

    test('initial setup') do |activity|
      assert_equal "What hath Matz wrought?", @text_view.text
    end

    test('button changes text') do |activity|
      button = activity.findViewById(43)
      button.performClick
      assert_equal "What hath Matz wrought!", @text_view.text
    end

You run the tests for your app using ant or rake

    $ jruby -S rake test

    $ cd test ; ant run-tests

Contributing
------------

Want to contribute? Great! Meet us in #ruboto on irc.freenode.net, fork the project and start coding!

"But I don't understand it well enough to contribute by forking the project!" That's fine. Equally helpful:

* Use Ruboto and tell us how it could be better.
* As you gain wisdom, contribute it to [the wiki](http://github.com/ruboto/ruboto/wiki/)
* When you gain enough wisdom, reconsider whether you could fork the project.

If contributing code to the project, please run the existing tests and add tests for your changes.  You run the tests using rake

    $ jruby -S rake test

Getting Help
------------

* You'll need to be pretty familiar with the Android API. The [Developer Guide](http://developer.android.com/guide/index.html) and [Reference](http://developer.android.com/reference/packages.html) are very useful.
* There is further documentation at the [wiki](http://github.com/ruboto/ruboto/wiki)
* If you have bugs or feature requests, [open an issue on GitHub](http://github.com/ruboto/ruboto/issues)
* You can ask questions in #ruboto on irc.freenode.net and on the [mailing list](http://groups.google.com/groups/ruboto)
* There are some sample scripts (just Activities) [here](http://github.com/ruboto/ruboto-irb/tree/master/assets/demo-scripts/)

Tips & Tricks
-------------

### Emulators

If you're doing a lot of Android development, you'll probably find yourself typing `emulator -avd name_of_emulator` a lot to open emulators. It can be convenient to alias these to shorter commands.

For example, in your `~/.bashrc`, `~/.zshrc`, or similar file, you might put
    alias eclair="emulator -avd eclair"
    alias froyo="emulator -avd froyo"
If you have an "eclair" emulator that runs Android 2.1 and a "froyo" one that runs Android 2.2.


Alternatives
------------

If Ruboto's performance is a problem for you, check out [Mirah](http://mirah.org/) and [Garrett](http://github.com/technomancy/Garrett).

Mirah is a language with Ruby-like syntax that compiles to java files. This means that it adds no big runtime dependencies and has essentially the same performance as writing Java code because it essentially generates the same Java code that you would write. This makes it extremely well-suited for mobile devices where performance is a much bigger consideration.

Garrett is a "playground for Mirah exploration on Android."


Domo Arigato
------------

Thanks go to:

* Charles Nutter, a member of the JRuby core team, for mentoring this RSoC project and starting the Ruboto project in the first place with an [irb](http://github.com/ruboto/ruboto-irb)
* All of Ruby Summer of Code's [sponsors](http://rubysoc.org/sponsors)
* [Engine Yard](http://engineyard.com/) in particular for sponsoring RSoC and heavily sponsoring JRuby, which is obviously critical to the project.
* All [contributors](http://github.com/ruboto/ruboto/contributors) and [contributors to the ruboto-irb project](http://github.com/ruboto/ruboto-irb/contributors), as much of this code was taken from ruboto-irb.
