package THE_PACKAGE;

import android.test.ActivityInstrumentationTestCase2;
import android.app.ProgressDialog;
import org.ruboto.Script;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import junit.framework.Test;
import junit.framework.TestResult;
import junit.framework.TestSuite;
import android.util.Log;

/**
 * This is a simple framework for a test of an Application.  See
 * {@link android.test.ApplicationTestCase ApplicationTestCase} for more information on
 * how to write and extend Application tests.
 * <p/>
 * To run this test, you can type:
 * adb shell am instrument -w \
 * -e class THE_PACKAGE.InheritingTestTest \
 * org.ruboto.test.tests/android.test.InstrumentationTestRunner
 */
public class InheritingTestTest extends ActivityInstrumentationTestCase2<InheritingTest> {
    private final String script;

    public InheritingTestTest(String script) {
        super("THE_PACKAGE", InheritingTest.class);
        this.script = script;
        setName(script);
        Log.d("InheritingTestTest", "Instance: " + script);
    }

    public static Test suite() {
        Log.d("InheritingTestTest", "suite(): ");
        Test suite = ActivityInstrumentationTestCase2.suite();
        Log.d("InheritingTestTest", "suite: " + suite);
        return suite;
    }

    public void run(TestResult result) {
        Log.d("InheritingTestTest", "run: " + script);
        super.run(result);
    }

    public void runTest() throws Exception {
        Log.d("InheritingTestTest", "runTest: " + script);
        for (String f : getInstrumentation().getContext().getResources().getAssets().list("scripts")) {
            Log.d("InheritingTestTest", "icra scripts asset: " + f);
            // suite.addTest((Test)c.getConstructor(String.class).newInstance("ruboto_sample_app_activity_test.rb"));
        }
        Script.setUpJRuby(null);
        Script.defineGlobalVariable("$test", this);

        InputStream is = getInstrumentation().getContext().getResources().getAssets().open("scripts/ruboto_sample_app_activity_test.rb");
        BufferedReader buffer = new BufferedReader(new InputStreamReader(is));
        StringBuilder source = new StringBuilder();
        while (true) {
            String line = buffer.readLine();
            if (line == null) break;
            source.append(line).append("\n");
        }
        buffer.close();
        Script.exec(source.toString());
    }

}
