package THE_PACKAGE;

import android.test.ActivityInstrumentationTestCase2;
import android.app.ProgressDialog;
import org.ruboto.Script;
import java.io.IOException;
import junit.framework.Test;
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
    public InheritingTestTest() {
        super("THE_PACKAGE", InheritingTest.class);
    }

//    public static Test suite() {
//        for (String f : getActivity().getAssets().list("scripts")) {
//            java.lang.System.out.println(f);
//        }
//        Script.copyScriptsIfNeeded(getActivity().getFilesDir().getAbsolutePath() + "/scripts", getActivity().getAssets());
//        for (String f : getActivity().getAssets().list("scripts")) {
//            suite.addTest(new InheritingTest(f));
//        }
//        return suite;
//    }

    public void runTest() {
        try {
            Script.setUpJRuby(null);
            Script.defineGlobalVariable("$test", this);
            new Script("start.rb").execute();
        } catch(IOException e){
            e.printStackTrace();
            ProgressDialog.show(this.getActivity(), "Test failed", e.getMessage(), true, true);
        }
    }

}
