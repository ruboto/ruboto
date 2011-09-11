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
import org.ruboto.Script;

public class ActivityTest extends ActivityInstrumentationTestCase2 {
    private final Object setup;
    private final Object block;
    private final String filename;

    public ActivityTest(Class activityClass, String filename, Object setup, String name, Object block) {
        super(activityClass.getPackage().getName(), activityClass);
        this.filename = filename;
        this.setup = setup;
        setName(filename + "#" + name);
        this.block = block;
        Log.i(getClass().getName(), "Instance: " + getName());
    }

    public void runTest() throws Exception {
        Log.i(getClass().getName(), "runTest");
        Log.i(getClass().getName(), "runTest: " + getName());
        if (Script.setUpJRuby(getActivity())) {
            Log.i(getClass().getName(), "ruby ok");
            try {
                final Activity activity = getActivity();
                Log.i(getClass().getName(), "activity ok");
                runTestOnUiThread(new Runnable() {
                    public void run() {
                        String oldFile = Script.getScriptFilename();

                        Log.i(getClass().getName(), "calling setup");
                        Script.setScriptFilename(filename);
                        Script.callMethod(setup, "call", activity);
                        Log.i(getClass().getName(), "setup ok");
                    
                        Script.setScriptFilename(filename);
                        Script.callMethod(block, "call", activity);
                        Script.setScriptFilename(oldFile);
                    }
                });
            } catch (Throwable t) {
                throw new AssertionFailedError(t.getMessage() != null ? t.getMessage() : t.getClass().getName());
            }
            Log.i(getClass().getName(), "runTest ok");
        } else {
            throw new AssertionFailedError("Ruboto Core platform is missing.");
        }
    }

}
