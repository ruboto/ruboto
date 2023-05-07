Contributing
============

Want to contribute? Great!  We look forward to what you can do.

## Communication

Meet us in #ruboto on irc.freenode.net or on [https://gitter.im/ruboto/ruboto]
or on the Google Group.

## How to contribute

Fork the project and start coding!  :)

    "But I don't understand it well enough to contribute by forking the project!"

That's fine. Equally helpful:

* Use Ruboto and tell us how it could be better.
  Report [issues](http://github.com/ruboto/ruboto/issues).
* Browse http://ruboto.org/ and the documentation, and let us know how to make
  it better.
* As you gain wisdom, contribute it to
  [the wiki](http://github.com/ruboto/ruboto/wiki).
* When you gain enough wisdom, reconsider whether you could fork the project.

If contributing code to the project, please run the existing tests and add tests
for your changes.  You run the tests using rake:

    $ rake test

We have set up a matrix test that tests multiple configuations on the emulator:

    $ ./matrix_tests.sh

All branches and pull requests on GitHub are also tested on
[https://travis-ci.org/ruboto/ruboto](https://travis-ci.org/ruboto/ruboto).

## Chores

Ruboto uses linkedin/dexmaker to generate classes at runtime.  It should be downloaded from

https://bintray.com/linkedin/maven/dexmaker

and be placed in `assets/libs/dexmaker-x.y.z.jar` when new versiopns are available and useful.
