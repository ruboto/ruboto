package org.ruboto.test;

import android.app.Activity;
import android.app.ProgressDialog;
import android.test.ActivityInstrumentationTestCase2;
import android.util.Log;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import junit.framework.AssertionFailedError;
import junit.framework.Test;
import junit.framework.TestResult;
import junit.framework.TestSuite;
import org.ruboto.JRubyAdapter;

public class ActivityTest extends ActivityInstrumentationTestCase2 {
    private final Object setup;
    private final Object block;
    private final String filename;
    private final boolean onUiThread;

    public ActivityTest(Class activityClass, String filename, Object setup, String name, boolean onUiThread, Object block) {
        super(activityClass.getPackage().getName(), activityClass);
        this.filename = filename;
        this.setup = setup;
        setName(filename + "#" + name);
        this.onUiThread = onUiThread;
        this.block = block;
        Log.i(getClass().getName(), "Instance: " + getName());
    }

    public void runTest() throws Exception {
        try {
            Log.i(getClass().getName(), "runTest: " + getName());
            final Activity activity = getActivity();
            Log.i(getClass().getName(), "Activity OK");
            Runnable testRunnable = new Runnable() {
                public void run() {
                    String oldFile = JRubyAdapter.getScriptFilename();

                    Log.i(getClass().getName(), "calling setup");
                    JRubyAdapter.setScriptFilename(filename);
                    JRubyAdapter.callMethod(setup, "call", activity);
                    Log.i(getClass().getName(), "setup ok");
                    
                    JRubyAdapter.setScriptFilename(filename);
                    JRubyAdapter.callMethod(block, "call", activity);
                    JRubyAdapter.setScriptFilename(oldFile);
                }
            };
            if (onUiThread) {
                runTestOnUiThread(testRunnable);
            } else {
                testRunnable.run();
            }
            Log.i(getClass().getName(), "runTest ok");
        } catch (Throwable t) {
            AssertionFailedError afe = new AssertionFailedError("Exception running test.");
            afe.initCause(t);
            throw afe;
        }
    }

}
