Ruboto Core
=============

Ruby on Android.

Installation
-------

    gem install ruboto-core    <===  Not released, yet :)

Getting Started
---------------

Before you use Ruboto, you should do the following things:

* Install the JDK if it's not on your system already
* Install [the Android SDK](http://developer.android.com/sdk/index.html)
* Add the sdk's `tools/` directory to your `$PATH`

Features
-------

* [Application generator](#application_generator) (like the rails application generator)
* [Packaging task](#packaging_task) to generate an apk file
* [Deployment task](#deployment_task) to deploy a generated package to an emulator or connected device
* Update path when ruboto is updated, either by "gem update" or "rake ruboto:update" (not decided, yet)

<a name="application_generator">
### Application generator
</a>

Make sure the "android" command is in your path:

    ruboto.rb gen app --package com.yourdomain.whatever --path path/to/where/you/want/the/app --name NameOfApp --target android-8


<a name="packaging_task">
### Packaging task
</a>

This will generate an apk file.

    rake

<a name="deployment_task">
### Deployment task
</a>

Not implemented, yet.

### Updating Ruboto

Not implemented, yet.


Contributing
------------

Want to contribute? Great! Meet us on #ruboto on irc.freenode.net, fork the project and start coding!

### Building the gem

    rake gem

### Publishing the gem

    rake release

Tips & Tricks
-------------

### Emulators

If you're doing a lot of Android development, you'll probably find yourself typing `emulator -avd name_of_emulator` a lot to open emulators. It can be convenient to alias these to shorter commands.

For example, in your `~/.bashrc`, `~/.zshrc`, or similar file, you might put
    alias eclair="emulator -avd eclair"
    alias froyo="emulator -avd froyo"
If you have an "eclair" emulator that runs Android 2.1 and a "froyo" one that runs Android 2.2.
