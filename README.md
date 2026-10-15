# Ruboto 2

Ruboto 2 is a redesign based on an [Android Studio](https://developer.android.com/studio/) workflow.
This means that the JRuby and Ruboto components will integrate into the standard gradle tooling used by
regular Android Studio projects.

## Quick start: build the Todo sample app

You need a JDK (17+), the Android SDK (set `ANDROID_HOME`), and Ruby.
No Android Studio required.  Apps built with JRuby 10 run on
**Android 13 (API 33) or newer** by default, and on **Android 6.0 (API 23)
or newer** when generated with `--min-sdk` — see
[Older Android versions](#older-android-versions).

```shell
# 1. Get ruboto
git clone https://github.com/ruboto/ruboto.git
cd ruboto && bundle install && cd ..

# 2. Generate an app named "Todo" (installs the latest JRuby automatically)
ruby -Iruboto/lib ruboto/bin/ruboto gen app --package org.ruboto.todo --name Todo --path todo

# 3. Make it a todo list app
cp ruboto/assets/samples/todo_activity.rb todo/app/src/main/resources/todo_activity.rb

# 4. Build the APK
cd todo && gradle assembleDebug

# 5. Install it on your phone (enable USB debugging first)
adb install app/build/outputs/apk/debug/app-debug.apk
```

The whole app is one Ruby file: [`assets/samples/todo_activity.rb`](assets/samples/todo_activity.rb).
Edit it, rebuild, reinstall — that is the entire development cycle.

### Older Android versions

JRuby 10 uses `java.lang.invoke` (MethodHandles exist on Android from 8.0,
VarHandles only from 13), `java.nio.file` and `java.time` (8.0) and a few
newer JDK methods.  Pass a lower `--min-sdk` to build for older devices,
down to Android 6.0 — e.g. a cheap digital photo frame:

```shell
ruby -Iruboto/lib ruboto/bin/ruboto gen app --package org.ruboto.todo --name Todo --path todo --min-sdk 23
```

For a minimum SDK below 33, Ruboto then rewrites the jruby-core jar when it
installs JRuby so it does not need `java.lang.invoke` at all:

* references to `java.lang.invoke` move to a small stand-in built on
  reflection and `sun.misc.Unsafe`
  ([`lib/jruby10_legacy/runtime`](lib/jruby10_legacy/runtime));
* signature-polymorphic calls (`MethodHandle.invokeExact`, `VarHandle`
  access) become calls to generated static bridges;
* JRuby's socket library gets stand-ins for the `java.net` socket option and
  protocol family types (Android 7+), so `require 'socket'` and `net/http`
  work on Android 6.

At every minimum SDK, calls to JDK methods newer than the device
(`java.lang.ClassValue` only exists from Android 14 and JRuby 10.1 needs it
at startup; `InputStream.readAllBytes`, `StringBuilder.isEmpty`,
`BigInteger.TWO`, …) are retargeted to backports.

Below API 26 the generated `app/build.gradle` also turns on core library
desugaring for `java.nio.file`, `java.time` and `java.util.function`.

JRuby's runtime is interpreted on Android either way; the stand-in adds some
reflection overhead (instance variables and Java calls are noticeably slower
than on Android 13+).  Starting JRuby on an Android 6 quad-core Cortex-A7 takes
about 20 seconds.

The minimum SDK is read from `app/build.gradle` whenever JRuby is installed
(`gen app`, `gen jruby`, `update jruby`).  To lower it for an existing app, set
`minSdk` (and below 26 the desugaring lines a new app gets) in
`app/build.gradle`, then run `ruboto update jruby --force` so the jar is
rewritten.

### Calling Java with Ruby callbacks

Android cannot load classes generated at runtime, so Ruboto implements Java
interfaces with `java.lang.reflect.Proxy`.  Blocks, procs,
`SomeInterface.impl { }` and Ruby classes that `include` a Java interface all
work:

```ruby
button.setOnClickListener { |view| toast 'clicked' }
button.setOnClickListener(proc { |view| toast 'clicked' })
java.lang.Thread.new(java.lang.Runnable.impl { puts 'running' }).start
```

Java default methods are not forwarded automatically: if Java code calls a
default method of the interface (e.g. `Predicate#negate`), define it in the Ruby
class, or use `SomeInterface.impl { |name, *args| ... }`, which receives every
call.  Each conversion creates a new proxy, so to cancel something later (e.g.
`Handler#removeCallbacks`) keep the converted Java object
(`proc.to_java(java.lang.Runnable)`) or use `Handler` messages.  Subclassing a
Java class in Ruby (`class MyList < java.util.ArrayList`) still needs runtime
class generation and does not work.

### Standard library

The Java parts of `stringio`, `strscan`, `json` and `psych` (YAML) ship as
separate jars inside JRuby, which Android cannot load; Ruboto merges their
classes into the app.  The bundled gems that work on Android (`abbrev`,
`base64`, `benchmark`, `bigdecimal`, `csv`, `drb`, `getoptlong`, `logger`,
`matrix`, `mutex_m`, `observer`, `ostruct`, `prime`, `pstore`,
`resolv-replace`, `rexml`, `rinda`) are copied onto the standard library's
load path, since RubyGems is off on Android.  Other gems, including bundled
development tools like `minitest` or `rake`, can be vendored as described in
[Using gems](#using-gems).  `openssl` is not available.

### Using gems

RubyGems itself is disabled on Android (it cannot scan gem specifications
inside the APK), but pure-Ruby gems work fine: put their `lib` files into
`app/src/main/resources`, which is on the load path inside the APK, and
`require` them as usual.  The Todo sample uses the
[humanize](https://rubygems.org/gems/humanize) gem this way:

```shell
gem fetch humanize && gem unpack humanize-*.gem
cp -r humanize-*/lib/* todo/app/src/main/resources/
```

Vendor a gem's runtime dependencies the same way.  Gems with native (C)
extensions do not work; look for a pure-Ruby or Java-based alternative.

Watch out for dependencies that look like they are already there.  `humanize`
requires `bigdecimal`, which JRuby ships as a *default gem* under
`META-INF/jruby.home/lib/ruby/gems/`, and the generated `build.gradle` excludes
that whole tree to keep the APK small.  So it is in JRuby but not in your APK,
and the app dies on launch with `cannot load such file -- bigdecimal`.  Vendor
it like any other gem:

```shell
gem fetch bigdecimal && gem unpack bigdecimal-*.gem
cp -r bigdecimal-*/lib/* todo/app/src/main/resources/
```

## Sample: an IRB console

[`assets/samples/irb_activity.rb`](assets/samples/irb_activity.rb) is a REPL you
can carry around.  Type Ruby, get a value back; the binding persists between
lines and anything the line prints is captured and shown.

```shell
ruby -Iruboto/lib ruboto/bin/ruboto gen app --package org.ruboto.irb --name Irb --path irb
cp ruboto/assets/samples/irb_activity.rb irb/app/src/main/resources/irb_activity.rb
cd irb && gradle assembleDebug && adb install app/build/outputs/apk/debug/app-debug.apk
```

It installs gems too — `gem install humanize` at the prompt downloads the
`.gem`, unpacks its `lib` into the app's private storage and puts it on
`$LOAD_PATH`, so it survives restarts.  RubyGems is never involved, which is
what makes it possible here at all.  Dependencies are not resolved: if a
`require` fails, install what it names the same way.  That needs one line added
to `app/src/main/AndroidManifest.xml`, above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### On Wear OS

[`assets/samples/wear_irb_activity.rb`](assets/samples/wear_irb_activity.rb) is
the same idea sized for a watch: the crown scrolls the transcript, `clear`
empties it, and there is a dictation button because typing Ruby on a watch is
miserable.  It does not install gems.

Generate it the same way, then make it a watch app by adding to
`app/src/main/AndroidManifest.xml` — inside `<manifest>`:

```xml
<uses-feature android:name="android.hardware.type.watch"/>
<queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>
```

and inside `<application>`, which also wants
`android:theme="@android:style/Theme.DeviceDefault"` and
`android:enableOnBackInvokedCallback="true"`:

```xml
<meta-data android:name="com.google.android.wearable.standalone" android:value="true"/>
<uses-library android:name="com.google.android.wearable" android:required="false"/>
```

Expect a slow first start.  JRuby's runtime initialisation is around twenty
seconds on watch hardware before the script is even read; it happens on a
background thread behind the splash, so it is a wait rather than a hang.

## Starting a new Ruboto project

* Download and install [Android studio](https://developer.android.com/studio/).

* Choose "Create New Project" in the startup screen.
  * Choose "Phone and Tablet" and "No Activity" for the project template.
  * Choose "Java" for your language and "Minimum SDK" should be "**API 27: Android 8.1 (Oreo)**" or higher.

* Add a **jcenter** to the `dependencyResolutionManagement/repositories` section of your `settings.gradle` file:
  ```groovy
  dependencyResolutionManagement {
      ...
      repositories {
          ...
          jcenter()
      }
  }
  ```

* Add the these dependencies to your `app/build.gradle` file:
  ```groovy
  dependencies {
    ...
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation 'com.linkedin.dexmaker:dexmaker:2.19.1'
    implementation 'me.qmx.jitescript:jitescript:0.4.1'
    implementation 'com.jakewharton.android.repackaged:dalvik-dx:7.1.0_r7'
  }
  ```

* Add `gems.rb` file:
  ```ruby
  source 'https://rubygems.org/'

  gem 'ruboto', '~>2.0.dev', git: 'https://github.com/ruboto/ruboto.git'
  ```

* Ensure you are using JRuby on the command line

  Create a `.ruby-version` file:
  ```text
    jruby
  ```

* Initialize Ruboto:
  ```shell
  jruby -S bundle
  jruby -S bundle exec ruboto init
  ```

  This will copy the core files to your project.


* Add `app/gems.rb`
  ```ruby
  source 'https://rubygems.org/'

  gem 'activerecord', '~>7.0'
  gem 'activerecord-jdbc-adapter', '~>70.1'
  gem 'sqldroid', '~>1.0'
  ```

* Add `app/update_jruby_jar.sh`:
  ```shell
  #!/usr/bin/env bash
  set -e

  VERSION="9.4.2.0"
  FULL_VERSION="${VERSION}"
  # FULL_VERSION="${VERSION}-SNAPSHOT" # Uncomment to use a local snapshot
  # FULL_VERSION="${VERSION}-20190822.050313-17" # Uncomment to use a remote snapshot
  JAR_FILE="jruby-complete-${FULL_VERSION}.jar"
  DOWNLOAD_DIR="$HOME/Downloads"
  DOWNLOADED_JAR="${DOWNLOAD_DIR}/${JAR_FILE}"
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

  cd $SCRIPT_DIR

  [ ! -d $HOME/Downloads ] && mkdir $HOME/Downloads  # Create the directory if we don't find it
  [ ! -d ./libs ] && mkdir ./libs                    # Create the directory if we don't find it

  cd libs
  rm -f bcpkix-jdk15on-*.jar bcprov-jdk15on-*.jar bctls-jdk15on-*.jar cparse-jruby.jar generator.jar jline-*.jar jopenssl.jar jruby-complete-*.jar parser.jar psych.jar readline.jar snakeyaml-*.jar

  if test -f "${DOWNLOADED_JAR}"; then
    echo "Found downloaded JAR"
  else
    echo No "${DOWNLOADED_JAR}" - Downloading.
    curl "https://oss.sonatype.org/service/local/repositories/releases/content/org/jruby/jruby-complete/${VERSION}/jruby-complete-${VERSION}.jar" -o "${DOWNLOADED_JAR}"
  fi
  cp ${DOWNLOADED_JAR} .

  unzip -o -j ${JAR_FILE} '*.jar'

  # FIXME(uwe): Why do we delete these files?
  zip generator.jar -d json/ext/ByteListTranscoder.class
  zip generator.jar -d json/ext/OptionsReader.class
  zip generator.jar -d json/ext/Utils.class
  zip generator.jar -d json/ext/RuntimeInfo.class

  cd - >/dev/null

  cd src/main/java
  find * -type f | grep "org/jruby/" | sed -e 's/\.java//g' | sort > ../../../overridden_classes.txt
  cd - >/dev/null

  while read p; do
    unzip -Z1 libs/${JAR_FILE} | grep "$p\\.class" > classes.txt
    unzip -Z1 libs/${JAR_FILE} | egrep "$p(\\\$[^$]+)*\\.class" >> classes.txt
    if [[ -s classes.txt ]] ; then
      zip -d -@ libs/${JAR_FILE} <classes.txt
      if [[ ! "$?" == "0" ]] ; then
        zip -d libs/${JAR_FILE} "$p\\.class"
      fi
    fi
    rm classes.txt
  done < overridden_classes.txt

  rm overridden_classes.txt
  
  cd libs
  rm -f digest.jar
  cd - >/dev/null
  ```

* Make `app/update_jruby_jar.sh` executable:
  ```shell
    chmod u+x app/update_jruby_jar.sh
  ```

* Generate `jruby.jar`:
  ```shell
    app/update_jruby_jar.sh
  ```

* Generate the startup activity:
  ```shell
    bundle exec ruboto gen class Activity --name StartupActivity
  ```

* Add the startup activity intent filter to the new activity tag in `app/src/main/AndroidManifest.xml`:
  ```xml
  <activity android:name='StartupActivity' android:exported="true">
      <intent-filter>
          <action android:name="android.intent.action.MAIN" />
          <category android:name="android.intent.category.LAUNCHER" />
          <action android:name="android.intent.action.VIEW" />
      </intent-filter>
  </activity>
  ```

* Declare the Ruboto components and SplashActivity in `app/src/main/AndroidManifest.xml`
  ```xml
  <activity android:name='org.ruboto.RubotoActivity' />
  <activity android:name='org.ruboto.RubotoDialog' android:theme='@android:style/Theme.Dialog' />
  <service
      android:name='org.ruboto.RubotoService'
      android:exported='false' />
  <activity
      android:name='org.ruboto.SplashActivity'
      android:configChanges='orientation|screenSize'
      android:exported='false'
      android:noHistory='true' />
  ```

  **Rember to sync the gradle config after the changes.**

 
* Start your app!

## Updating app gems

Update your `app/gems.rb` (or `app/Gemfile`) and run
  ```shell
  bundle exec rake bundle
  ```

## Adding Ruboto to an existing Android Studio project

HOWTO missing.  Pull requests welcome!

# Ruboto 1.x

Looking for Ruboto 1.x?  Switch to the [ruboto_1.x](https://github.com/ruboto/ruboto/tree/ruboto_1.x) branch.
