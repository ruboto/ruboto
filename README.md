# Ruboto 2

Ruboto 2 is a redesign based on an [Android Studio](https://developer.android.com/studio/) workflow.
This means that the JRuby and Ruboto components will integrate into the standard gradle tooling used by
regular Android Studio projects.

## Starting a new Ruboto project

* Download and install [Android studio](https://developer.android.com/studio/).
* Choose "Create New Project" in the startup screen.
  * Choose "Phone and Tablet" and "No Activity" for the project template.
  * Choose "Java" for your language and "Minimum SDK" should be "API 27" or higher.
  * "Use legacy android.support libraries" ?  "No", for now.
* Add the these dependencies to your `app/build.gradle` file:
  ```groovy
    implementation fileTree(dir: 'libs', include: ['*.jar'])
    implementation 'com.linkedin.dexmaker:dexmaker:2.19.1'
    implementation 'me.qmx.jitescript:jitescript:0.4.1'
    implementation 'com.jakewharton.android.repackaged:dalvik-dx:7.1.0_r7'
  ```
* Initialize Ruboto:

      bundle exec ruboto init

  This will copy the core files to your project.


* Add `app/gems.rb`
  ```ruby
  source 'https://rubygems.org/'

  gem 'activerecord', '~>5.2'
  gem 'activerecord-jdbc-adapter', '~>52.6'
  gem 'sqldroid', '~>1.0'
  ```

* Install the app gems:

      jruby -S rake bundle

* Add `app/update_jruby_jar.sh`:
  ```shell
  #!/usr/bin/env bash
  set +e
  
  VERSION="9.2.9.0"
   FULL_VERSION="${VERSION}"
  # FULL_VERSION="${VERSION}-SNAPSHOT" # Uncomment to use a local snapshot
  # FULL_VERSION="${VERSION}-20190822.050313-17" # Uncomment to use a remote snapshot
  JAR_FILE="jruby-complete-${FULL_VERSION}.jar"
  DOWNLOAD_DIR="$HOME/Downloads"
  DOWNLOADED_JAR="${DOWNLOAD_DIR}/${JAR_FILE}"
  
  cd libs
  rm -f bcpkix-jdk15on-*.jar bcprov-jdk15on-*.jar bctls-jdk15on-*.jar cparse-jruby.jar generator.jar jline-*.jar jopenssl.jar jruby-complete-*.jar parser.jar psych.jar readline.jar snakeyaml-*.jar
  
  if test -f "${DOWNLOADED_JAR}"; then
    echo "Found downloaded JAR"
  else
    echo No "${DOWNLOADED_JAR}" - Downloading.
    curl "https://oss.sonatype.org/service/local/repositories/releases/content/org/jruby/jruby-complete/${VERSION}/jruby-complete-${VERSION}.jar" -o "${DOWNLOADED_JAR}"
  fi
  cp ${DOWNLOADED_JAR} .
  
  unzip -j ${JAR_FILE} '*.jar'
  
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
  ```

* Make `app/update_jruby_jar.sh` executable:

      chmod u+x app/update_jruby_jar.sh

* Generate `jruby.jar`:

      cd app
      ./update_jruby_jar.sh

* What next?

## Adding Ruboto to an existing Android Studio project

HOWTO missing.  Pull requests welcome!

# Ruboto 1.x

Looking for Ruboto 1.x?  Switch to the [ruboto_1.x](https://github.com/ruboto/ruboto/tree/ruboto_1.x) branch.
