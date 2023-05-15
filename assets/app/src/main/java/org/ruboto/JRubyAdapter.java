package org.ruboto;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;

import org.jruby.embed.LocalContextScope;
import org.jruby.embed.LocalVariableBehavior;

import java.io.File;
import java.io.PrintStream;

public class JRubyAdapter {
    private static org.jruby.embed.ScriptingContainer ruby;
    private static boolean isDebugBuild = false;
    private static PrintStream output = null;
    private static boolean initialized = false;
    private static LocalContextScope localContextScope = LocalContextScope.SINGLETON; // FIXME(uwe):  Why not CONCURRENT ?  Help needed!
    private static LocalVariableBehavior localVariableBehavior = LocalVariableBehavior.TRANSIENT;

    public static Object get(String name) {
        return ruby.get(name);
    }

    public static String getScriptFilename() {
        return ruby.getScriptFilename();
    }

    public static Object runRubyMethod(Object receiver, String methodName, Object... args) {
        return ruby.runRubyMethod(Object.class, receiver, methodName, args);
    }

    @SuppressWarnings("unchecked")
    public static <T> T runRubyMethod(Class<T> returnType, Object receiver, String methodName, Object... args) {
        return ruby.runRubyMethod(returnType, receiver, methodName, args);
    }

    public static boolean isDebugBuild() {
        return isDebugBuild;
    }

    public static boolean isInitialized() {
        return initialized;
    }

    public static void put(String name, Object object) {
        ruby.put(name, object);
    }

    public static Object runScriptlet(String code) {
        return ruby.runScriptlet(code);
    }

    public static boolean setUpJRuby(Context appContext) {
        return setUpJRuby(appContext, output == null ? System.out : output);
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    public static synchronized boolean setUpJRuby(Context appContext, PrintStream out) {
        if (!initialized) {
            setDebugBuild(appContext);
            Log.d("Setting up JRuby " + org.jruby.runtime.Constants.VERSION
                    + " (" + (isDebugBuild ? "DEBUG" : "RELEASE") + ")"
                    + "  Max memory: " + (Runtime.getRuntime().maxMemory() / (1024 * 1024)) + "MB");
            setSystemProperties(appContext);

            try {
                //////////////////////////////////
                //
                // Set jruby.home
                // This needs to be set before the ScriptingContainer is initialized
                //
                String apkName;
                try {
                    apkName = appContext.getPackageManager()
                            .getApplicationInfo(appContext.getPackageName(), 0).sourceDir;
                    final String jrubyHome = "jar:file:" + apkName + "!/META-INF/jruby.home";
                    Log.i("Setting JRUBY_HOME: " + jrubyHome);
                    System.setProperty("jruby.home", jrubyHome);
                } catch (NameNotFoundException e) {
                    e.printStackTrace();
                    throw new RuntimeException("Exception setting JRUBY_HOME", e);
                }

                //////////////////////////////////
                //
                // Determine Output
                //

                if (out != null) {
                    output = out;
                }

                //////////////////////////////////
                //
                // Disable rubygems
                //
                org.jruby.RubyInstanceConfig config = new org.jruby.RubyInstanceConfig();
//                config.setDisableGems(true);

                ClassLoader classLoader = JRubyAdapter.class.getClassLoader();
                config.setLoader(classLoader);

                if (output != null) {
                    config.setOutput(output);
                    config.setError(output);
                }

                // This will become the global runtime and be used by our ScriptingContainer
                org.jruby.Ruby.newInstance(config);

                //////////////////////////////////
                //
                // Create the ScriptingContainer
                //
                ruby = new org.jruby.embed.ScriptingContainer(localContextScope, localVariableBehavior);

                // FIXME(uwe): Write tutorial on profiling.
                // container.getProvider().getRubyInstanceConfig().setProfilingMode(mode);

                Thread.currentThread().setContextClassLoader(classLoader);

                String scriptsDir = scriptsDirName(appContext);
                addLoadPath(scriptsDir);
                addLoadPath("jar:file:" + apkName + "!/");
                addLoadPath("uri:classloader:/");
                if (appContext.getFilesDir() != null) {
                    String defaultCurrentDir = appContext.getFilesDir().getPath();
                    Log.d("Setting JRuby current directory to " + defaultCurrentDir);
                    ruby.setCurrentDirectory(defaultCurrentDir);
                } else {
                    Log.e("Unable to find app files dir!");
                    if (new File(scriptsDir).exists()) {
                        Log.d("Changing JRuby current directory to " + scriptsDir);
                        ruby.setCurrentDirectory(scriptsDir);
                    }
                }

                put("$package_name", appContext.getPackageName());
                put("APK_PATH", "jar:file:" + apkName + "!");

                runScriptlet("::RUBOTO_JAVA_PROXIES = {}");

                // TODO(uwe):  Add a way to display startup progress.
                put("APPLICATION_CONTEXT", appContext.getApplicationContext());
                put("$application_context", appContext.getApplicationContext());
                runScriptlet("begin\n  require 'environment'\nrescue LoadError => e\n  puts e\nend");

                initialized = true;
            } catch (IllegalArgumentException e) {
                handleInitException(e);
            } catch (SecurityException e) {
                handleInitException(e);
            }
        }
        return initialized;
    }

    private static void setSystemProperties(Context appContext) {
        System.setProperty("jruby.backtrace.style", "normal"); // normal raw full mri
        System.setProperty("jruby.bytecode.version", "1.6");
        // System.setProperty("jruby.compile.backend", "DALVIK");
        System.setProperty("jruby.compile.mode", "OFF"); // OFF OFFIR JITIR? FORCE FORCEIR
        System.setProperty("jruby.interfaces.useProxy", "true");
        System.setProperty("jruby.ir.passes", "LocalOptimizationPass,DeadCodeElimination");
        System.setProperty("jruby.management.enabled", "false");
        System.setProperty("jruby.native.enabled", "false");
        System.setProperty("jruby.objectspace.enabled", "false");
        System.setProperty("jruby.rewrite.java.trace", "true");
        System.setProperty("jruby.thread.pooling", "true");

        // Uncomment these to debug/profile Ruby source loading
        // Analyse the output: grep "LoadService:   <-" | cut -f5 -d- | cut -c2- | cut -f1 -dm | awk '{total = total + $1}END{print total}'
        // System.setProperty("jruby.debug.loadService", "true");
        // System.setProperty("jruby.debug.loadService.timing", "true");

        // Used to enable JRuby to generate proxy classes
        System.setProperty("jruby.ji.upper.case.package.name.allowed", "true");
        System.setProperty("jruby.class.cache.path", appContext.getDir("dex", 0).getAbsolutePath());
        System.setProperty("java.io.tmpdir", appContext.getCacheDir().getAbsolutePath());
        System.setProperty("sun.arch.data.model", "64");
    }

    public static void setScriptFilename(String name) {
        ruby.setScriptFilename(name);
    }

    public static Boolean addLoadPath(String scriptsDir) {
        if (new File(scriptsDir).exists() || scriptsDir.equals("uri:classloader:/") || scriptsDir.endsWith("/base.apk!/")) {
            Log.i("Added directory to load path: " + scriptsDir);
            Script.addDir(scriptsDir);
            runScriptlet("$:.unshift '" + scriptsDir + "' ; $:.uniq! ; p $:");
            return true;
        } else {
            Log.i("Extra scripts dir not present: " + scriptsDir);
            return false;
        }
    }

    public static void setLocalContextScope(LocalContextScope val) {
        localContextScope = val;
    }

    public static void setLocalVariableBehavior(LocalVariableBehavior val) {
        localVariableBehavior = val;
    }

    // Private methods

    private static void handleInitException(Exception e) {
        Log.e("Exception starting JRuby");
        Log.e(e.getMessage() != null ? e.getMessage() : e.getClass().getName());
        e.printStackTrace();
        ruby = null;
    }

    private static String scriptsDirName(Context context) {
        File storageDir;
        if (isDebugBuild()) {
            storageDir = context.getExternalFilesDir(null);
            if (storageDir == null) {
                Log.e("Development mode active, but sdcard is not available.  Make sure you have added\n<uses-permission android:name='android.permission.WRITE_EXTERNAL_STORAGE' />\nto your AndroidManifest.xml file.");
                storageDir = context.getFilesDir();
            }
        } else {
            storageDir = context.getFilesDir();
        }
        File scriptsDir = new File(storageDir, "scripts");
        if ((!scriptsDir.exists() && !scriptsDir.mkdirs())) {
            Log.e("Unable to create the scripts dir.");
            scriptsDir = new File(context.getFilesDir(), "scripts");
        }
        return scriptsDir.getAbsolutePath();
    }

    private static void setDebugBuild(Context context) {
        PackageManager pm = context.getPackageManager();
        PackageInfo pi;
        try {
            pi = pm.getPackageInfo(context.getPackageName(), 0);
            isDebugBuild = ((pi.applicationInfo.flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0);
        } catch (NameNotFoundException e) {
            isDebugBuild = false;
        }
    }

    public static void setOutputStream(PrintStream out) {
        if (ruby == null) {
            output = out;
        } else {
            ruby.setOutput(out);
            ruby.setError(out);
        }
    }
}
