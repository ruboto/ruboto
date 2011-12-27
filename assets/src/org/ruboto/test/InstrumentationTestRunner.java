package org.ruboto.test;

import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.JarURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.jar.JarFile;
import java.util.jar.JarEntry;
import java.util.List;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.ruboto.Script;
import java.util.Set;
import java.util.HashSet;

public class InstrumentationTestRunner extends android.test.InstrumentationTestRunner {
    private Class activityClass;
    private Object setup;
    private TestSuite suite;
    
    public TestSuite getAllTests() {
        Log.i(getClass().getName(), "Finding test scripts");
        suite = new TestSuite("Sweet");
        
        try {
            if (Script.setUpJRuby(getTargetContext())) {
                Script.defineGlobalVariable("$runner", this);
                Script.defineGlobalVariable("$test", this);
                Script.defineGlobalVariable("$suite", suite);

                loadScript("test_helper.rb");

                String test_apk_path = getContext().getPackageManager().getApplicationInfo(getContext().getPackageName(), 0).sourceDir;
                JarFile jar = new JarFile(test_apk_path);
                Enumeration<JarEntry> entries = jar.entries();
                while(entries.hasMoreElements()) {
                    JarEntry entry = entries.nextElement();
                    String name = entry.getName();
                    if (name.indexOf("/") >= 0 || !name.endsWith(".rb")) {
                        continue;
                    }
                    if (name.equals("test_helper.rb")) continue;
                    loadScript(name);
                }
            } else {
                addError(suite, new RuntimeException("Ruboto Core platform is missing"));
            }
        } catch (android.content.pm.PackageManager.NameNotFoundException e) {
            addError(suite, e);
        } catch (IOException e) {
          addError(suite, e);
        } catch (RuntimeException e) {
          addError(suite, e);
        }
        return suite;
    }

    public void activity(Class activityClass) {
        this.activityClass = activityClass;
    }

    public void setup(Object block) {
        this.setup = block;
    }

    public void test(String name, Object block) {
        if (android.os.Build.VERSION.SDK_INT <= 8) {
          name ="runTest";
        }
        Test test = new ActivityTest(activityClass, Script.getScriptFilename(), setup, name, block);
        suite.addTest(test);
        Log.d(getClass().getName(), "Made test instance: " + test);
    }

    private void addError(TestSuite suite, Throwable t) {
        Throwable cause = t;
        while(cause != null) {
          Log.e(getClass().getName(), "Exception loading tests: " + cause);
          t = cause;
          cause = t.getCause();
        }
        final Throwable rootCause = t;
        rootCause.printStackTrace();
        suite.addTest(new TestCase(t.getMessage()) {
            public void runTest() throws java.lang.Throwable {
                throw rootCause;
            }
        });
    }

    private void loadScript(String f) throws IOException {
        Log.d(getClass().getName(), "Loading test script: " + f);
        InputStream is = getClass().getClassLoader().getResourceAsStream(f);
        BufferedReader buffer = new BufferedReader(new InputStreamReader(is));
        StringBuilder source = new StringBuilder();
        while (true) {
            String line = buffer.readLine();
            if (line == null) break;
            source.append(line).append("\n");
        }
        buffer.close();

        String oldFilename = Script.getScriptFilename();
        Script.setScriptFilename(f);
        Script.put("$script_code", source.toString());
        Script.setScriptFilename(f);
        Script.execute("$test.instance_eval($script_code)");
        Script.setScriptFilename(oldFilename);
        Log.d(getClass().getName(), "Test script " + f + " loaded");
    }

}
