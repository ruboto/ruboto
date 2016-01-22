[![Gem Version](https://badge.fury.io/rb/ruboto.svg)](http://badge.fury.io/rb/ruboto)
[![Build Status](https://travis-ci.org/ruboto/ruboto.svg?branch=master)](https://travis-ci.org/ruboto/ruboto)
[![Code Climate](https://codeclimate.com/github/ruboto/ruboto.svg)](https://codeclimate.com/github/ruboto/ruboto)

Ruboto (JRuby on Android) is a platform for developing full stand-alone apps for
Android using the Ruby language and libraries.  It includes support libraries
and generators for creating projects, classes, tests, and more.  The complete
APIs of Android, Java, and Ruby are available to you using the Ruby language.

Installation
------------

To use Ruboto you need a [Ruby](http://ruby-lang.org/) implementation like
[MRI](http://ruby-lang.org/),
[JRuby](http://jruby.org/),
or [Rubinius](http://rubini.us/)
installed.  Using a tool like
[rvm](https://rvm.io)
or [pik](https://github.com/vertiginous/pik)
is recommended.

Then run

    $ gem install ruboto
    
### From source

    git clone https://github.com/ruboto/ruboto.git
    cd ruboto
    rake install

If you are unfamiliar with Ruby gems, you can get more information at
 [rubygems.org](http://guides.rubygems.org/).
 

Tools
---------------

Ruboto offers a setup command to help you with the component installation and
configuration:

    $ ruboto setup -y

This should install the following tools if not already present:

* A Java Development Kit (JDK)
* [The Android SDK](http://developer.android.com/sdk/index.html)
* [Apache ANT](http://ant.apache.org/)
* [jruby-jars](https://rubygems.org/gems/jruby-jars)

* Add the sdk to the "ANDROID_HOME" environment variable as an absolute path
  (Java does not expand tildes `~`)
* Add the sdk's `tools`, `build-tools`, and `platform-tools/` directory to your
  "PATH" environment variable.

Emulator
--------

Ruboto offers a command to help you create and run the emulator for a given
version (api-level) of Android.

    $ ruboto emulator -t android-17

See [Emulator](http://developer.android.com/guide/developing/tools/emulator.html)
for more information on emulators.

Command-line Tools
------------------

* [Application generator](#application_generator) (like the Rails application generator)
* [Class generator](#class_generator) to generate additional Activities, BroadcastReceivers, Services, etc.
* [Callback generator](#class_generator) to generate specific subclasses to open up access (callbacks) for various portions of the Android API
* [Packaging task](#packaging_task) to generate an .apk file
* [Release task](#release_task) to deploy a generated package to an emulator or connected device
* [Develop without having to compile to try every change](#update_scripts)


<a name="application_generator"></a>
### Application generator

    $ ruboto gen app --package com.yourdomain.whatever

You can specify lots of parameters if you don't want the defaults.

    $ ruboto gen app --package com.yourdomain.whatever --path path/to/where/you/want/the/app --name NameOfApp --target android-version --min-sdk another-android-version --activity MainActivityName

Version values must be specified using the sdk level number (e.g., 22 is
Lollipop).  You can prefix with `android-` (e.g. android-22).  


<a name="class_generator"></a>
### Class generator

Generates a Java class (Activity, Service, or BroadcastReceiver) associated with a specific Ruboto script.  The generator also generates a corresponding test script.

    $ ruboto gen class ClassName --name YourObjectName
For example:

    $ ruboto gen class BroadcastReceiver --name AwesomenessReceiver

<a name="callback_generator"></a>
### Callback generator

You can subclass any part of the Android API to pass control over to a script when the specified methods are called. You can also create classes that implement a single Android interface to pass control over to Ruboto.

Starting with Ruboto 0.6.0 there are easy ways to do this within your scripts.
The new way of generating interfaces and subclasses is described in the wiki page
[Generating classes for callbacks](https://github.com/ruboto/ruboto/wiki/Generating-classes-for-callbacks).

<a name="packaging_task"></a>
### Packaging task

This will generate an .apk file:

    $ rake debug

To generate an .apk and install it to a connected device (or emulator) all in one go, run:

    $ rake install

To start the installed app, run:

    $ rake start

You can chain these commands:

    $ rake install start

<a name="release_task"></a>
### Release task

When you're ready to post your app to the Market, run the `release` task.

    $ rake release

This will generate a keystore for you if it is not already present.
It will ask for a password for the keystore and one for the key itself.  Make
sure that you remember those two passwords, as well as the alias for the key.

Also make sure to keep your key backed up (if you lose it, you won't be able to
release updates to your app that can install right over the old versions), but
secure.

Now get that .apk to the market!

<a name="update_scripts"></a>
### Updating Your Scripts on a Device

With traditional Android development, you have to recompile your app and
reinstall it on your test device/emulator every time you make a change. That's
slow and annoying.

Luckily, with Ruboto, most of your changes are in the scripts, not in the
compiled Java files. So if your changes are Ruby-only, you can just run

    $ rake update_scripts

to have it copy the current version of your scripts to your device.
To update the scripts and restart the app in one go, run:

    $ rake update_scripts:restart

Sorry if this takes away your excuse to have sword fights:

![XKCD Code's Compiling](http://imgs.xkcd.com/comics/compiling.png)

Caveats:

This only works if your changes are all Ruby. If you have Java changes (which
would generally just mean generating new classes) or changes to the xml, you
will need to recompile your app.  The `update_scripts` task will revert to
build the complete .apk and install it if it detects non-Ruby source changes.

On an actual device, you need to give the `WRITE_EXTERNAL_STORAGE` permission to
your app, and scripts will be updated using the SDCARD on the device/emulator.

Alternatively, you can also root your phone.

### Updating Ruboto's Files

You can update various portions of your generated Ruboto app through the `ruboto` command:

* JRuby:

1) If a new version of JRuby is released, you should update your gem (e.g., sudo gem update jruby-jars).

2) From the root directory of your app:

    $ ruboto update jruby

* The Ruboto library files and generated Java source:

1) From the root directory of your app:

    $ ruboto update app


Scripts
-------

The main thing Ruboto offers you is the ability to write Ruby scripts to define
the behavior of Activities, BroadcastReceivers, and Services. (Eventually, it'll
be every class. It's set up such that adding in more classes should be trivial.)

Here's how it works:

First of all, your scripts are found in the `src/` directory, and the script
name is the same as the name of your class, only under_scored instead of
CamelCased. Android classes have some standard methods that get called in certain
situations. `Activity.onDestroy()` gets called when the activity gets killed,
for example. Save weird cases (like the "launching" methods that are needed to set up
JRuby), to call the method `onFooBar()`, you call the Ruby method `onFooBar` on the
Android object. 

That was really abstract, so here's an example. You generate an app with the option `--activity FooActivity`, which means that
Ruboto will generate a FooActivity for you. So you open `src/foo_activity.rb` in
your favorite text editor. If you want an activity that does nothing but Log
when it gets launched and when it gets destroyed (in the `onCreate` and `onPause`
methods,) you want your script to look like this:

```ruby
class FooActivity
  def onCreate(bundle)
    super
    android.util.Log.v 'MYAPPNAME', 'onCreate got called!'
  end

  def onPause
    super
    android.util.Log.v 'MYAPPNAME', 'onPause got called!'
  end
end
```

The arguments passed to the methods are the same as the arguments that the Java
methods take. Consult the Android documentation for more information.

Activities also have some special methods defined to make things easier. The
easiest way to get an idea of what they are is looking over the
[demo scripts](http://github.com/ruboto/ruboto-irb/tree/master/assets/demo-scripts/)
and the
[tests](http://github.com/ruboto/ruboto/tree/master/test/activity/).
You can also read the
[Ruboto source](http://github.com/ruboto/ruboto/blob/master/assets/src/ruboto)
where everything is defined.

We also have many fine examples on the
[Wiki](https://github.com/ruboto/ruboto/wiki).

Testing
-------

For each generated class, a Ruby test script is created in the `test/src`
directory.  For example, if you generate a RubotoSampleAppActivity, the file
`test/src/ruboto_sample_app_activity_test.rb` is created containing a
sample test script:

```ruby
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
```

You can run the tests for your app using ant or rake:

    $ rake test

    $ cd test ; ant run-tests

Contributing
------------

Want to contribute? Great! Meet us in #ruboto on irc.freenode.net, fork the
project and start coding!

"But I don't understand it well enough to contribute by forking the project!"
That's fine. Equally helpful:

* Use Ruboto and tell us how it could be better.
* Browse http://ruboto.org/ and the documentation, and let us know how to make
  it better.
* As you gain wisdom, contribute it to
  [the wiki](http://github.com/ruboto/ruboto/wiki/)
* When you gain enough wisdom, reconsider whether you could fork the project.

If contributing code to the project, please run the existing tests and add tests
for your changes.  You run the tests using rake:

    $ rake test

We have set up a matrix test that tests multiple configuations on the emulator:

    $ ./matrix_tests.sh

All branches and pull requests on GitHub are also tested on
[https://travis-ci.org/ruboto/ruboto](https://travis-ci.org/ruboto/ruboto).

Getting Help
------------

* You'll need to be pretty familiar with the Android API. The
  [Developer Guide](http://developer.android.com/guide/index.html) and
  [Reference](http://developer.android.com/reference/packages.html) are very
  useful.
* There is further documentation at the
  [wiki](http://github.com/ruboto/ruboto/wiki).
* If you have bugs or feature requests, please
  [open an issue on GitHub](http://github.com/ruboto/ruboto/issues).
* You can ask questions in #ruboto on irc.freenode.net and on the
  [mailing list](http://groups.google.com/groups/ruboto).
* There are some sample scripts (just Activities)
  [here](http://github.com/ruboto/ruboto-irb/tree/master/assets/demo-scripts/).

Tips & Tricks
-------------

### Emulators

You can start an emulator corresponding to the api level of your project with:

    $ ruboto emulator

The emulator will be created for you and will be named after the Android version
of your project, like "Android_4.0.3".

If you want to start an emulator for a specific API level use the `-t` option:

    $ ruboto emulator -t 17

If you're doing a lot of Android development, you'll probably find yourself
starting emulators a lot. It can be convenient to alias these to shorter
commands.

For example, in your `~/.bashrc`, `~/.zshrc`, or similar file, you might put

```sh
alias ics="ruboto emulator -t 15"
alias jellyb="ruboto emulator -t 16"
alias jb17="ruboto emulator -t 17"
```

Alternatives
------------

If Ruboto's performance is a problem for you, check out
[Mirah](http://mirah.org/) and [Garrett](http://github.com/technomancy/Garrett).

Mirah is a language with Ruby-like syntax that compiles to Java files. This
means that it adds no big runtime dependencies and has essentially the same
performance as writing Java code, as it essentially generates the same Java
code that you would write. This makes it extremely well-suited for mobile
devices where performance is a much bigger consideration.

Garrett is a "playground for Mirah exploration on Android."


Domo Arigato
------------

Thanks go to:

* Charles Nutter, a member of the JRuby core team, for mentoring this RSoC
  project and starting the Ruboto project in the first place with an
  [irb](http://github.com/ruboto/ruboto-irb).
* All of Ruby Summer of Code's [sponsors](http://rubysoc.org/sponsors).
* [Engine Yard](http://engineyard.com/) in particular for sponsoring RSoC and
  heavily sponsoring JRuby, which is obviously critical to the project.
* All [contributors](http://github.com/ruboto/ruboto/contributors) and
  [contributors to the ruboto-irb project](http://github.com/ruboto/ruboto-irb/contributors),
  as much of this code was taken from ruboto-irb.
