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
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.ruboto.Script;

public class ActivityTest extends ActivityInstrumentationTestCase2 {
    private final IRubyObject setup;
    private final IRubyObject block;

    public ActivityTest(Class activityClass, IRubyObject setup, String name, IRubyObject block) {
        super(activityClass);
        setName(name);
        this.setup = setup;
        this.block = block;
        Log.d(getClass().getName(), "Instance: " + name);
    }

    public void runTest() throws Exception {
        Log.d(getClass().getName(), "runTest");
        Log.d(getClass().getName(), "runTest: " + getName());
        Script.setUpJRuby(null);
        Log.d(getClass().getName(), "ruby ok");
        try {
            final Activity activity = getActivity();
            Log.d(getClass().getName(), "activity ok");
            runTestOnUiThread(new Runnable() {
                public void run() {
                    Log.d(getClass().getName(), "calling setup");
                    RuntimeHelpers.invoke(setup.getRuntime().getCurrentContext(), setup, "call",
                            JavaUtil.convertJavaToRuby(Script.getRuby(), activity));
                    Log.d(getClass().getName(), "setup ok");
                    RuntimeHelpers.invoke(block.getRuntime().getCurrentContext(), block, "call",
                            JavaUtil.convertJavaToRuby(Script.getRuby(), activity));
                }
            });
        } catch (Throwable t) {
            throw new AssertionFailedError(t.getMessage());
        }
        Log.d(getClass().getName(), "runTest ok");
    }

}
