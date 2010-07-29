Ruboto Core
=============

The core components of Ruby on Android.

Features
-------

* [Application generator](#application_generator) (like the rails application generator)
* [Packaging task](#packaging_task) to generate an apk file
* [Deployment task](#deployment_task) to deploy a generated package to an emulator or connected device
* Update path when ruboto is updated, either by "gem update" or "rake ruboto:update" (not decided, yet)

Contributing
------------

Want to contribute? Great! Meet us on #ruboto on irc.freenode.net, fork the project and start coding!

<a name="application_generator">
### Application generator
</a>

    ruby -rubygems /path/to/ruboto-core/bin/ruboto.rb gen app --package com.yourdomain.whatever --path path/to/where/you/want/the/app --name Name --target android-8


<a name="packaging_task">
### Packaging task
</a>

Not implemented, yet.

<a name="deployment_task">
### Deployment task
</a>

Not implemented, yet.

We will have options to deploy either the full apk or just push your application files.

### Updating Ruboto

Not implemented, yet.

