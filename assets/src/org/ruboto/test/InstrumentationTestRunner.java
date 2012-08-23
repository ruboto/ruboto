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
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.Enumeration;
import java.util.jar.JarFile;
import java.util.jar.JarEntry;
import java.util.List;
import java.util.Map;
import junit.framework.Test;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.ruboto.JRubyAdapter;
import java.util.Set;
import java.util.HashSet;

public class InstrumentationTestRunner extends android.test.InstrumentationTestRunner {
    private Class activityClass;
    private Object setup;
    private Object teardown;
    private TestSuite suite;
    
    public TestSuite getAllTests() {
        Log.i(getClass().getName(), "Finding test scripts");
        suite = new TestSuite("Sweet");
        String loadStep = "Setup JRuby";
        
        try {
            final AtomicBoolean JRubyLoadedOk = new AtomicBoolean();

            // TODO(uwe):  Running with large stack is currently only needed when running with JRuby 1.7.0 and android-10
            // TODO(uwe):  Simplify when we stop support for JRuby 1.7.0 or android-10
            Thread t = new Thread(null, new Runnable() {
                public void run() {
                    JRubyLoadedOk.set(JRubyAdapter.setUpJRuby(getTargetContext()));
                    if (!JRubyAdapter.isJRubyPreOneSeven()) {
                        JRubyAdapter.runScriptlet("Java::OrgRubotoTest::InstrumentationTestRunner.__persistent__ = true");
                    }
                }
            }, "Setup JRuby from instrumentation test runner", 64 * 1024);
            try {
                t.start();
                t.join();
            } catch(InterruptedException ie) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Interrupted starting JRuby", ie);
            }
            // TODO end

            if (JRubyLoadedOk.get()) {
                loadStep = "Load test helper";
                // TODO(uwe):  Running with large stack is currently only needed when running with JRuby 1.7.0.dev and android-10
                // TODO(uwe):  Simplify when we stop support for JRuby 1.7.0.dev or android-10
                final IOException[] ioex = new IOException[]{null};
                Thread t2 = new Thread(null, new Runnable() {
                    public void run() {
                        try {
                            loadScript("test_helper.rb");
                        } catch (IOException e) {
                            ioex[0] = e;
                        }
                    }
                }, "Setup JRuby from instrumentation test runner", 64 * 1024);
                try {
                    t2.start();
                    t2.join();
                } catch(InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    throw new RuntimeException("Interrupted starting JRuby", ie);
                }
                if (ioex[0] != null) {
                    throw ioex[0];
                }
                // TODO end

                loadStep = "Get app test source dir";
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
                    loadStep = "Load " + name;
                    loadScript(name);
                    setup = teardown = null;
                }
            } else {
                addError(suite, loadStep, new RuntimeException("Ruboto Core platform is missing"));
            }
        } catch (android.content.pm.PackageManager.NameNotFoundException e) {
            addError(suite, loadStep, e);
        } catch (IOException e) {
          addError(suite, loadStep, e);
        } catch (RuntimeException e) {
          addError(suite, loadStep, e);
        }
        return suite;
    }

    public void activity(Class activityClass) {
        this.activityClass = activityClass;
    }

    public void setup(Object block) {
        this.setup = block;
    }

    public void teardown(Object block) {
        this.teardown = block;
    }

    public void test(String name, Object block) {
        test(name, null, block);
    }

    public void test(String name, Map options, Object block) {
        // FIXME(uwe): Remove when we stop supporting Android 2.2
        if (android.os.Build.VERSION.SDK_INT <= 8) {
          name ="runTest";
        }
        // FIXME end

        boolean runOnUiThread = options == null || options.get("ui") == "true";

        Test test = new ActivityTest(activityClass, JRubyAdapter.getScriptFilename(), setup, teardown, name, runOnUiThread, block);
        suite.addTest(test);
        Log.d(getClass().getName(), "Made test instance: " + test);
    }

    private void addError(TestSuite suite, String loadStep, Throwable t) {
        Throwable cause = t;
        while(cause != null) {
          Log.e(getClass().getName(), "Exception loading tests (" + loadStep + "): " + cause);
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
        JRubyAdapter.setScriptFilename(f);

        // FIXME(uwe):  Simplify when we stop supporting JRuby < 1.7.0
        if (JRubyAdapter.isJRubyPreOneSeven()) {
            JRubyAdapter.put("$test", this);
            JRubyAdapter.put("$script_code", source.toString());
            JRubyAdapter.put("$filename", f);
            JRubyAdapter.runScriptlet("$test.instance_eval($script_code, $filename)");
        } else {
            if (f.equals("test_helper.rb")) {
                JRubyAdapter.runScriptlet(source.toString());
            } else {
                JRubyAdapter.runRubyMethod(this, "instance_eval", source.toString(), f);
            }
        }
        Log.d(getClass().getName(), "Test script " + f + " loaded");
    }

}
