package THE_PACKAGE;

import android.test.ActivityInstrumentationTestCase2;
import android.widget.TextView;

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

    private InheritingTest mActivity;  // the activity under test
    private TextView mView;          // the activity's TextView (the only view)
    private String resourceString;

    public InheritingTestTest() {
        super("THE_PACKAGE", InheritingTest.class);
    }

    @Override
    protected void setUp() throws Exception {
        super.setUp();
        mActivity = this.getActivity();
        resourceString = "What hath Matz wrought?";
        long start = System.currentTimeMillis();
        while (mView == null) {
            if (System.currentTimeMillis() - start > 60000) break;
            Thread.sleep(1000);
            mView = (TextView) mActivity.findViewById(42);
        }
        assertNotNull(mView);
    }

    public void testPreconditions() throws Exception {
      assertNotNull(mView);
    }

    public void testText() throws Exception {
        assertEquals(resourceString, (String) mView.getText());
    }

}
