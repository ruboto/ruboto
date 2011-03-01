package org.ruboto.test;

import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
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
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.RubyClass;
import org.jruby.runtime.builtin.IRubyObject;
import org.ruboto.Script;

public class InstrumentationTestRunner extends android.test.InstrumentationTestRunner {
    private Class activityClass;
    private IRubyObject setup;
    private TestSuite suite;
    
    public TestSuite getAllTests() {
        Log.i(getClass().getName(), "Finding test scripts");
        suite = new TestSuite("Sweet");
        
        try {
            Script.setUpJRuby(null);
            Script.defineGlobalVariable("$runner", this);
            Script.defineGlobalVariable("$test", this);
            Script.defineGlobalVariable("$suite", suite);
            loadScript("test_helper.rb");
            String[] scripts = getContext().getResources().getAssets().list("scripts");
            for (String f : scripts) {
                if (f.equals("test_helper.rb")) continue;
                Log.i(getClass().getName(), "Found script: " + f);
                loadScript(f);
            }
        } catch (IOException e) {
          addError(suite, e);
        } catch (RaiseException e) {
          addError(suite, e);
        }
        return suite;
    }

    public void activity(Class activityClass) {
        this.activityClass = activityClass;
    }

    public void setup(IRubyObject block) {
        this.setup = block;
    }

    public void test(String name, IRubyObject block) {
        if (android.os.Build.VERSION.SDK_INT <= android.os.Build.VERSION_CODES.FROYO) {
          name ="runTest";
        }
        Test test = new ActivityTest(activityClass, setup, name, block);
        suite.addTest(test);
        Log.d(getClass().getName(), "Made test instance: " + test);
    }

    private void addError(TestSuite suite, final Throwable t) {
        Log.e(getClass().getName(), "Exception loading tests: " + t);
        suite.addTest(new TestCase(t.getMessage()) {
            public void runTest() throws java.lang.Throwable {
                throw t;
            }
        });
    }

    private void loadScript(String f) throws IOException {
        InputStream is = getContext().getResources().getAssets().open("scripts/" + f);
        BufferedReader buffer = new BufferedReader(new InputStreamReader(is));
        StringBuilder source = new StringBuilder();
        while (true) {
            String line = buffer.readLine();
            if (line == null) break;
            source.append(line).append("\n");
        }
        buffer.close();

        Log.d(getClass().getName(), "Loading test script: " + f);
        Script.defineGlobalVariable("$script_code", source.toString());
        Script.exec("$test.instance_eval($script_code)");
        Log.d(getClass().getName(), "Test script loaded");
    }

}
