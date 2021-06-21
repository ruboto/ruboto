/*
 * Copyright 2013 ThinkFree
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.ruboto;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.os.Build;
import android.util.Log;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Observable;
import java.util.Observer;

import dalvik.system.PathClassLoader;

/**
 * Easy class loading for multi-dex Android application.
 *
 * 1) call validateClassPath() from Application.onCreate()
 * 2) check dexOptRequired then addAllJARsAssets() on non-UI thread.
 *
 * @author Alan Goo
 */
public class DexDex {
    public static final String DIR_SUBDEX = "dexdex";

    private static final String TAG = "DexDex";

    private static final int SDK_INT_ICS = 14;
    private static final int SDK_INT_KITKAT = 19;
    private static final int SDK_INT_MARSHMALLOW = 23;

    private static final int BUF_SIZE = 8 * 1024;
    public static final int PROGRESS_COMPLETE = 100;

    private static ArrayList<String> theAppended = new ArrayList<String>();

    public static boolean debug = false;

    public static boolean dexOptRequired = false;

    private static Activity uiBlockedActivity = null;

    /**
     * just reuse existing interface for convenience
     * @hide
     */
    public static Observer dexOptProgressObserver = null;

    private DexDex() {
        // do not create an instance
    }

    private static boolean shouldDexOpt(File apkFile, File dexDir, String[] names) {
        boolean result = shouldDexOptImpl(apkFile, dexDir, names);
        if(debug) {
            Log.d(TAG, "shouldDexOpt(" + apkFile + "," + dexDir + "," + Arrays.deepToString(names) + ") => " + result
                + " on " + Thread.currentThread());
        }
        return result;
    }

    private static boolean shouldDexOptImpl(File apkFile, File dexDir, String[] names) {
        long apkDate = apkFile.lastModified();
        // APK upgrade case
        if(debug) {
            Log.d(TAG, "APK Date : " + apkDate + " ,dexDir date : " + dexDir.lastModified());
        }
        if (apkDate > dexDir.lastModified()) {
            return true;
        }
        // clean install (or crash during install) case
        for (int i = 0; i < names.length; i++) {
            String name = names[i];
            File dexJar = new File(dexDir, name);
            if (dexJar.exists()) {
                if (dexJar.lastModified() < apkDate) {
                    return true;
                }
            } else {
                return true;
            }
        }
        return false;
    }

    /**
     * Should be called from <code>Application.onCreate()</code>.
     * it returns quickly with little disk I/O.
     */
    public static void validateClassPath(final Context app) {
        try {
            String[] arrJars = createSubDexList(app);
            if(debug) {
                Log.d(TAG, "validateClassPath : " + Arrays.deepToString(arrJars));
            }
            File apkFile = new File(app.getApplicationInfo().sourceDir);
            final File dexDir = app.getDir(DIR_SUBDEX, Context.MODE_PRIVATE); // this API creates the directory if not exist
            dexOptRequired = shouldDexOpt(apkFile, dexDir, arrJars);
            if (dexOptRequired) {
                Thread dexOptThread = new Thread("DexDex - DexOpting for " + Arrays.deepToString(arrJars)) {
                    @Override
                    public void run() {
                        DexDex.addAllJARsInAssets(app);
                        // finished
                        dexOptRequired = false;

                        if(dexOptProgressObserver!=null) {
                            dexOptProgressObserver.update(null, PROGRESS_COMPLETE);
                            dexOptProgressObserver = null;
                        }

                        if (uiBlockedActivity != null) {
                            uiBlockedActivity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    // FIXME(uwe): Simplify when we stop supporting android-11
                                    // if (Build.VERSION.SDK_INT < 11) {
                                        Intent callerIntent = uiBlockedActivity.getIntent();
                                        uiBlockedActivity.finish();
                                        uiBlockedActivity.startActivity(callerIntent);
                                    // } else {
                                    //     uiBlockedActivity.recreate();
                                    // }
                                    // EMXIF
                                    uiBlockedActivity = null;
                                }
                            });
                        }
                    }
                };
                dexOptThread.start();
            } else {
                // all dex JAR are stable
                appendOdexesToClassPath(app, dexDir, arrJars);
            }
            if(debug) {
                Log.d(TAG, "validateClassPath - dexDir : " + dexDir);
            }
        } catch (IOException ex) {
            throw new RuntimeException(ex);
        }
    }

    /** find and append all JARs */
    public static void addAllJARsInAssets(final Context cxt) {
        try {
            if(debug) {
                Log.d(TAG, "addAllJARsInAssets on " + Thread.currentThread());
            }
            String[] arrJars = createSubDexList(cxt);
            copyJarsFromAssets(cxt, arrJars);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static String[] createSubDexList(final Context cxt) throws IOException {
        String[] files = cxt.getAssets().list("");
        ArrayList<String> jarList = new ArrayList<String>();
        for (int i = 0; i < files.length; i++) {
            String jar = files[i];
            if (jar.endsWith(".jar")) {
                jarList.add(jar);
            }
        }
        String[] arrJars = new String[jarList.size()];
        jarList.toArray(arrJars);
        return arrJars;
    }

    /**
     * MUST be called on non-Main Thread
     * @param names array of file names in 'assets' directory
     */
    public static void copyJarsFromAssets(final Context cxt, final String[] names) {
        if(debug) {
            Log.d(TAG, "copyJarsFromAssets(" + Arrays.deepToString(names) + ")");
        }
        final File dexDir = cxt.getDir(DIR_SUBDEX, Context.MODE_PRIVATE); // this API creates the directory if not exist
        File apkFile = new File(cxt.getApplicationInfo().sourceDir);
        // should copy subdex JARs to dexDir?
        final boolean shouldInit = shouldDexOpt(apkFile, dexDir, names);
        if (shouldInit) {
            try {
                copyToInternal(cxt, dexDir, names);
                appendOdexesToClassPath(cxt, dexDir, names);
            } catch (Exception e) {
                e.printStackTrace();
                throw new RuntimeException(e);
            }
        } else {
            if (!inAppended(names)) {
                appendOdexesToClassPath(cxt, dexDir, names);
            }
        }
    }

    /** checks if all <code>names</code> elements are in <code>theAppended</code> */
    private static boolean inAppended(String[] names) {
        for (int i = 0; i < names.length; i++) {
            if (!theAppended.contains(names[i])) {
                return false;
            }
        }
        return true;
    }

    /**
     * append DexOptimized dex files to the classpath.
     * @return true if additional DexOpt is required, false otherwise.
     */
    private static boolean appendOdexesToClassPath(Context cxt, File dexDir, String[] names) {
        // non-existing ZIP in classpath causes an exception on ICS
        // so filter out the non-existent
        String strDexDir = dexDir.getAbsolutePath();
        ArrayList<String> jarPaths = new ArrayList<String>();
        for (int i = 0; i < names.length; i++) {
            String jarPath = strDexDir + '/' + names[i];
            File f = new File(jarPath);
            if (f.isFile()) {
                jarPaths.add(jarPath);
            }
        }

        String[] jarsOfDex = new String[jarPaths.size()];
        jarPaths.toArray(jarsOfDex);

        PathClassLoader pcl = (PathClassLoader) cxt.getClassLoader();
        // do something dangerous
        try {
            if (Build.VERSION.SDK_INT < SDK_INT_ICS) {
                FrameworkHack.appendDexListImplUnderICS(jarsOfDex, pcl, dexDir);
            } else { // ICS+
                boolean kitkatPlus = Build.VERSION.SDK_INT >= SDK_INT_KITKAT;
                boolean marshmallowPlus = Build.VERSION.SDK_INT >= SDK_INT_MARSHMALLOW;
                ArrayList<File> jarFiles = DexDex.strings2Files(jarsOfDex);
                FrameworkHack.appendDexListImplICS(jarFiles, pcl, dexDir, kitkatPlus, marshmallowPlus);
            }
            // update theAppended if succeeded to prevent duplicated classpath entry
            for (String jarName : names) {
                theAppended.add(jarName);
            }
            if(debug) {
                Log.d(TAG, "appendOdexesToClassPath completed : " + pcl);
                Log.d(TAG, "theAppended : " + theAppended);
            }
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
        return true;
    }

    private static void copyToInternal(Context cxt, File destDir, String[] names) {
        String strDestDir = destDir.getAbsolutePath();
        AssetManager assets = cxt.getAssets();
        byte[] buf = new byte[BUF_SIZE];
        for (int i = 0; i < names.length; i++) {
            String name = names[i];
            String destPath = strDestDir + '/' + name;

            try {
                BufferedInputStream bis = new BufferedInputStream(assets.open(name));
                BufferedOutputStream bos = new BufferedOutputStream(new FileOutputStream(destPath));
                int len;
                while ((len = bis.read(buf, 0, BUF_SIZE)) > 0) {
                    bos.write(buf, 0, len);
                }
                bis.close();
                bos.close();
            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
        }
        destDir.setLastModified(System.currentTimeMillis());
    }

    private static ArrayList<File> strings2Files(String[] paths) {
        ArrayList<File> result = new ArrayList<File>(paths.length);
        int size = paths.length;
        for (int i = 0; i < size; i++) {
            result.add(new File(paths[i]));
        }
        return result;
    }

    public static void showUiBlocker(Activity startActivity, CharSequence title, CharSequence msg) {
        if(debug) {
            Log.d(TAG, "showUiBlocker() for " + startActivity);
        }
        uiBlockedActivity = startActivity;
        final ProgressDialog progressDialog = new ProgressDialog(startActivity);
        progressDialog.setMessage(msg);
        progressDialog.setTitle(title);
        progressDialog.setIndeterminate(true);
        dexOptProgressObserver = new Observer() {
            @Override
            public void update(Observable observable, Object o) {
                if(o==Integer.valueOf(PROGRESS_COMPLETE)) {
                    progressDialog.dismiss();
                }
            }
        };
        
        progressDialog.show();
    }
}
