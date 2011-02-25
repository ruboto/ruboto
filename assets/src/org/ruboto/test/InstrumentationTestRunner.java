package org.ruboto.test;

import android.util.Log;
import java.io.File;
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

public class InstrumentationTestRunner extends android.test.InstrumentationTestRunner {
    public TestSuite getAllTests() {
        TestSuite suite = new TestSuite("Sweet");
        try {
            java.util.List<java.lang.Class> testClasses = getClassesForPackage("org");
            testClasses = Arrays.asList(new Class[]{org.ruboto.sample_app.RubotoSampleAppActivityTest.class});
            for (Class c : testClasses) {
                Log.d("RUBOTO TEST", "Found class: " + c.getName());
                String[] scripts;
                try {
                  scripts = getContext().getResources().getAssets().list("scripts");
                } catch (IOException e) {
                    Log.e("RUBOTO TEST", "Exception listing scripts: " + e);
                    scripts = new String[]{"ruboto_sample_app_activity_test.rb"};
                }
                for (String f : scripts) {
                    Log.d("RUBOTO TEST", "Found script: " + f);
                    suite.addTest((Test)c.getConstructor(String.class).newInstance(f));
                }
            }
        } catch (NoSuchMethodException e) {
            Log.e("RUBOTO TEST", "NoSuchMethodException: " + e.getMessage());
        } catch (InstantiationException e2) {
            Log.e("RUBOTO TEST", "InstantiationException: " + e2.getMessage());
        } catch (IllegalAccessException e3) {
            Log.e("RUBOTO TEST", "IllegalAccessException: " + e3.getMessage());
        } catch (java.lang.reflect.InvocationTargetException e4) {
            Log.e("RUBOTO TEST", "InvocationTargetException: " + e4.getMessage());
        } catch (java.lang.ClassNotFoundException e) {
            // Huh?
        }
        suite.addTest(new TestCase("Success 2!") {
            public void runTest() {
                // Success!
            }
        });
        return suite;
    }

    public static List<Class> getClassesForPackage(String pckgname) throws ClassNotFoundException {
        Log.d("RUBOTO TEST", "Searching for classes in package: " + pckgname);
        // This will hold a list of directories matching the pckgname.
        //There may be more than one if a package is split over multiple jars/paths
        List<Class> classes = new ArrayList<Class>();
        ArrayList<File> directories = new ArrayList<File>();
        try {
            ClassLoader cld = Thread.currentThread().getContextClassLoader();
            if (cld == null) {
                throw new ClassNotFoundException("Can't get class loader.");
            }
            // Ask for all resources for the path
            Enumeration<URL> resources = cld.getResources(pckgname.replace('.', '/'));
        Log.d("RUBOTO TEST", "Searched");
            while (resources.hasMoreElements()) {
            Log.d("RUBOTO TEST", "Found resource");
                URL res = resources.nextElement();
            Log.d("RUBOTO TEST", "Found resource: " + res);
                if (res.getProtocol().equalsIgnoreCase("jar")){
                    JarURLConnection conn = (JarURLConnection) res.openConnection();
                    JarFile jar = conn.getJarFile();
                    for (JarEntry e:Collections.list(jar.entries())){
                        if (e.getName().startsWith(pckgname.replace('.', '/'))
                            && e.getName().endsWith(".class") && ! e.getName().contains("$")){
                            String className = e.getName().replace("/",".").substring(0,e.getName().length() - 6);
                            Log.d("RUBOTO TEST", className);
                            classes.add(Class.forName(className));
                        }
                    }
                }else
                    directories.add(new File(URLDecoder.decode(res.getPath(), "UTF-8")));
            }
        } catch (NullPointerException x) {
            throw new ClassNotFoundException(pckgname + " does not appear to be " +
                    "a valid package (Null pointer exception)");
        } catch (UnsupportedEncodingException encex) {
            throw new ClassNotFoundException(pckgname + " does not appear to be " +
                    "a valid package (Unsupported encoding)");
        } catch (IOException ioex) {
            throw new ClassNotFoundException("IOException was thrown when trying " +
                    "to get all resources for " + pckgname);
        }

        // For every directory identified capture all the .class files
        for (File directory : directories) {
            if (directory.exists()) {
                // Get the list of the files contained in the package
                String[] files = directory.list();
                for (String file : files) {
                    // we are only interested in .class files
                    if (file.endsWith(".class")) {
                        // removes the .class extension
                        classes.add(Class.forName(pckgname + '.'
                                + file.substring(0, file.length() - 6)));
                    }
                }
            } else {
                throw new ClassNotFoundException(pckgname + " (" + directory.getPath() +
                                    ") does not appear to be a valid package");
            }
        }
        return classes;
    }

}
