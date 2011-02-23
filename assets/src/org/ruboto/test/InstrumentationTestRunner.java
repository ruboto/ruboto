package org.ruboto.test;

import junit.framework.TestCase;
import junit.framework.TestSuite;

public class InstrumentationTestRunner extends android.test.InstrumentationTestRunner {
    public TestSuite getAllTests() {
        TestSuite suite = new TestSuite("Sweet");
        suite.addTest(new TestCase("Success!") {
            public void runTest() {
                // Success!
            }
        });
        suite.addTest(new TestCase("Success 2!") {
            public void runTest() {
                // Success!
            }
        });
        return suite;
    }

}
