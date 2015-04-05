package org.ruboto;

import java.io.File;
import java.io.FilenameFilter;
import java.io.PrintStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Build;
import android.os.Environment;
import dalvik.system.PathClassLoader;

public class JRubyAdapter {
    private static Object ruby;
    private static boolean isDebugBuild = false;
    private static PrintStream output = null;
    private static boolean initialized = false;
    private static String localContextScope = "SINGLETON"; // FIXME(uwe):  Why not CONCURRENT ?  Help needed!
    private static String localVariableBehavior = "TRANSIENT";
    private static String RUBOTO_CORE_VERSION_NAME;

    public static Object get(String name) {
        try {
            Method getMethod = ruby.getClass().getMethod("get", String.class);
            return getMethod.invoke(ruby, name);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            throw new RuntimeException(ite);
        }
    }

    public static String getPlatformVersionName() {
        return RUBOTO_CORE_VERSION_NAME;
    }

    public static String getScriptFilename() {
        return (String) callScriptingContainerMethod(String.class, "getScriptFilename");
    }

    public static Object runRubyMethod(Object receiver, String methodName, Object... args) {
        try {
            Method m = ruby.getClass().getMethod("runRubyMethod", Class.class, Object.class, String.class, Object[].class);
            return m.invoke(ruby, Object.class, receiver, methodName, args);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            printStackTrace(ite);
            if (isDebugBuild) {
                throw new RuntimeException(ite);
            }
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    public static <T> T runRubyMethod(Class<T> returnType, Object receiver, String methodName, Object... args) {
        try {
            Method m = ruby.getClass().getMethod("runRubyMethod", Class.class, Object.class, String.class, Object[].class);
            return (T) m.invoke(ruby, returnType, receiver, methodName, args);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            printStackTrace(ite);
        }
        return null;
    }

    public static boolean isDebugBuild() {
        return isDebugBuild;
    }

    public static boolean isInitialized() {
        return initialized;
    }

    public static void put(String name, Object object) {
        try {
            Method putMethod = ruby.getClass().getMethod("put", String.class, Object.class);
            putMethod.invoke(ruby, name, object);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            throw new RuntimeException(ite);
        }
    }

    public static Object runScriptlet(String code) {
        try {
            Method runScriptletMethod = ruby.getClass().getMethod("runScriptlet", String.class);
            return runScriptletMethod.invoke(ruby, code);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            if (isDebugBuild) {
                if (ite.getCause() instanceof RuntimeException) {
                    throw ((RuntimeException) ite.getCause());
                } else {
                    throw ((Error) ite.getCause());
                }
            } else {
                return null;
            }
        }
    }

    public static boolean setUpJRuby(Context appContext) {
        return setUpJRuby(appContext, output == null ? System.out : output);
    }

    @SuppressWarnings({ "unchecked", "rawtypes" })
    public static synchronized boolean setUpJRuby(Context appContext, PrintStream out) {
        if (!initialized) {
            Log.d("Max memory: " + (Runtime.getRuntime().maxMemory() / (1024 * 1024)) + "MB");
            // BEGIN Ruboto HeapAlloc
            // @SuppressWarnings("unused")
            // byte[] arrayForHeapAllocation = new byte[13 * 1024 * 1024];
            // arrayForHeapAllocation = null;
            // END Ruboto HeapAlloc
            setDebugBuild(appContext);
            Log.d("Setting up JRuby runtime (" + (isDebugBuild ? "DEBUG" : "RELEASE") + ")");
            System.setProperty("jruby.backtrace.style", "normal"); // normal raw full mri
            System.setProperty("jruby.bytecode.version", "1.6");
            // BEGIN Ruboto RubyVersion
            // System.setProperty("jruby.compat.version", "RUBY2_0"); // RUBY1_9 is the default in JRuby 1.7
            // END Ruboto RubyVersion
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
            System.setProperty("jruby.ji.proxyClassFactory", "org.ruboto.DalvikProxyClassFactory");
            System.setProperty("jruby.ji.upper.case.package.name.allowed", "true");
            System.setProperty("jruby.class.cache.path", appContext.getDir("dex", 0).getAbsolutePath());
            System.setProperty("java.io.tmpdir", appContext.getCacheDir().getAbsolutePath());

            // FIXME(uwe): Simplify when we stop supporting android-15
            if (Build.VERSION.SDK_INT >= 16) {
                DexDex.debug = true;
                DexDex.validateClassPath(appContext);
                while (DexDex.dexOptRequired) {
                    System.out.println("Waiting for class loader setup...");
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException ie) {}
                }
            }

            ClassLoader classLoader;
            Class<?> scriptingContainerClass;
            String apkName = null;

            try {
                scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer");
                System.out.println("Found JRuby in this APK");
                classLoader = JRubyAdapter.class.getClassLoader();
                try {
                    apkName = appContext.getPackageManager().getApplicationInfo(appContext.getPackageName(), 0).sourceDir;
                } catch (NameNotFoundException e) {}
            } catch (ClassNotFoundException e1) {
                String packageName = "org.ruboto.core";
                try {
                    PackageInfo pkgInfo = appContext.getPackageManager().getPackageInfo(packageName, 0);
                    apkName = pkgInfo.applicationInfo.sourceDir;
                    RUBOTO_CORE_VERSION_NAME = pkgInfo.versionName;
                } catch (PackageManager.NameNotFoundException e2) {
                    System.out.println("JRuby not found in local APK:");
                    e1.printStackTrace();
                    System.out.println("JRuby not found in platform APK:");
                    e2.printStackTrace();
                    return false;
                }

                System.out.println("Found JRuby in platform APK");
                classLoader = new PathClassLoader(apkName, JRubyAdapter.class.getClassLoader());

                try {
                    scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer", true, classLoader);
                } catch (ClassNotFoundException e) {
                    // FIXME(uwe): ScriptingContainer not found in the platform APK...
                    e.printStackTrace();
                    return false;
                }
            }

            try {
                //////////////////////////////////
                //
                // Set jruby.home
                //

                String jrubyHome = "file:" + apkName + "!/jruby.home";

                // FIXME(uwe): Remove when we stop supporting RubotoCore 0.4.7
                Log.i("RUBOTO_CORE_VERSION_NAME: " + RUBOTO_CORE_VERSION_NAME);
                if (RUBOTO_CORE_VERSION_NAME != null &&
                        (RUBOTO_CORE_VERSION_NAME.equals("0.4.7") || RUBOTO_CORE_VERSION_NAME.equals("0.4.8"))) {
                    jrubyHome = "file:" + apkName + "!";
                }
                // EMXIF

                Log.i("Setting JRUBY_HOME: " + jrubyHome);
                // This needs to be set before the ScriptingContainer is initialized
                System.setProperty("jruby.home", jrubyHome);

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

                Class rubyClass = Class.forName("org.jruby.Ruby", true, scriptingContainerClass.getClassLoader());
                Class rubyInstanceConfigClass = Class.forName("org.jruby.RubyInstanceConfig", true, scriptingContainerClass.getClassLoader());

                Object config = rubyInstanceConfigClass.getConstructor().newInstance();
                rubyInstanceConfigClass.getMethod("setDisableGems", boolean.class).invoke(config, true);
                rubyInstanceConfigClass.getMethod("setLoader", ClassLoader.class).invoke(config, classLoader);

                if (output != null) {
                    rubyInstanceConfigClass.getMethod("setOutput", PrintStream.class).invoke(config, output);
                    rubyInstanceConfigClass.getMethod("setError", PrintStream.class).invoke(config, output);
                }

                System.out.println("Ruby version: " + rubyInstanceConfigClass
                        .getMethod("getCompatVersion").invoke(config));

                // This will become the global runtime and be used by our ScriptingContainer
                rubyClass.getMethod("newInstance", rubyInstanceConfigClass).invoke(null, config);

                //////////////////////////////////
                //
                // Create the ScriptingContainer
                //

                Class scopeClass = Class.forName("org.jruby.embed.LocalContextScope", true, scriptingContainerClass.getClassLoader());
                Class behaviorClass = Class.forName("org.jruby.embed.LocalVariableBehavior", true, scriptingContainerClass.getClassLoader());

                ruby = scriptingContainerClass
                         .getConstructor(scopeClass, behaviorClass)
                         .newInstance(Enum.valueOf(scopeClass, localContextScope), 
                                      Enum.valueOf(behaviorClass, localVariableBehavior));

                // FIXME(uwe): Write tutorial on profiling.
                // container.getProvider().getRubyInstanceConfig().setProfilingMode(mode);

                // callScriptingContainerMethod(Void.class, "setClassLoader", classLoader);
                Method setClassLoaderMethod = ruby.getClass().getMethod("setClassLoader", ClassLoader.class);
                setClassLoaderMethod.invoke(ruby, classLoader);

                Thread.currentThread().setContextClassLoader(classLoader);

                String scriptsDir = scriptsDirName(appContext);
                addLoadPath(scriptsDir);
                if (appContext.getFilesDir() != null) {
                    String defaultCurrentDir = appContext.getFilesDir().getPath();
                    Log.d("Setting JRuby current directory to " + defaultCurrentDir);
                    callScriptingContainerMethod(Void.class, "setCurrentDirectory", defaultCurrentDir);
                } else {
                    Log.e("Unable to find app files dir!");
                    if (new File(scriptsDir).exists()) {
                        Log.d("Changing JRuby current directory to " + scriptsDir);
                        callScriptingContainerMethod(Void.class, "setCurrentDirectory", scriptsDir);
                    }
                }

                put("$package_name", appContext.getPackageName());

                runScriptlet("::RUBOTO_JAVA_PROXIES = {}");

                System.out.println("JRuby version: " + Class.forName("org.jruby.runtime.Constants", true, scriptingContainerClass.getClassLoader())
                        .getDeclaredField("VERSION").get(String.class));

                // TODO(uwe):  Add a way to display startup progress.
                put("$application_context", appContext.getApplicationContext());
                runScriptlet("begin\n  require 'environment'\nrescue LoadError => e\n  puts e\nend");

                initialized = true;
            } catch (ClassNotFoundException e) {
                handleInitException(e);
            } catch (IllegalArgumentException e) {
                handleInitException(e);
            } catch (SecurityException e) {
                handleInitException(e);
            } catch (InstantiationException e) {
                handleInitException(e);
            } catch (IllegalAccessException e) {
                handleInitException(e);
            } catch (InvocationTargetException e) {
                handleInitException(e);
            } catch (NoSuchMethodException e) {
                handleInitException(e);
            } catch (NoSuchFieldException e) {
                handleInitException(e);
            }
        }
        return initialized;
    }

    public static void setScriptFilename(String name) {
        callScriptingContainerMethod(Void.class, "setScriptFilename", name);
    }

    public static boolean usesPlatformApk() {
        return RUBOTO_CORE_VERSION_NAME != null;
    }

    public static Boolean addLoadPath(String scriptsDir) {
        if (new File(scriptsDir).exists()) {
            Log.i("Added directory to load path: " + scriptsDir);
            Script.addDir(scriptsDir);
            runScriptlet("$:.unshift '" + scriptsDir + "' ; $:.uniq!");
            return true;
        } else {
            Log.i("Extra scripts dir not present: " + scriptsDir);
            return false;
        }
    }

    // Private methods

    @SuppressWarnings("unchecked")
    private static <T> T callScriptingContainerMethod(Class<T> returnType, String methodName, Object... args) {
        Class<?>[] argClasses = new Class[args.length];
        for (int i = 0; i < argClasses.length; i++) {
            argClasses[i] = args[i].getClass();
        }
        try {
            Method method = ruby.getClass().getMethod(methodName, argClasses);
            T result = (T) method.invoke(ruby, args);
            return result;
        } catch (RuntimeException re) {
            re.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        } catch (InvocationTargetException e) {
            printStackTrace(e);
        } catch (NoSuchMethodException e) {
            e.printStackTrace();
        }
        return null;
    }

    private static void handleInitException(Exception e) {
        Log.e("Exception starting JRuby");
        Log.e(e.getMessage() != null ? e.getMessage() : e.getClass().getName());
        e.printStackTrace();
        ruby = null;
    }

    // FIXME(uwe):  Remove when we stop supporting Ruby 1.8
    @Deprecated public static boolean isRubyOneEight() {
        return ((String)get("RUBY_VERSION")).startsWith("1.8.");
    }

    // FIXME(uwe):  Remove when we stop supporting Ruby 1.8
    @Deprecated public static boolean isRubyOneNine() {
    String rv = ((String)get("RUBY_VERSION"));
        return rv.startsWith("2.1.") || rv.startsWith("2.0.") || rv.startsWith("1.9.");
    }

    static void printStackTrace(Throwable t) {
        // TODO(uwe):  Simplify this when Issue #144 is resolved
        // TODO(scott):  printStackTrace is causing too many problems
        //try {
        //    t.printStackTrace(output);
        //} catch (NullPointerException npe) {
            // TODO(uwe): t.printStackTrace() should not fail
            System.err.println(t.getClass().getName() + ": " + t);
            for (java.lang.StackTraceElement ste : t.getStackTrace()) {
                output.append(ste.toString() + "\n");
            }
        //}
    }

    private static String scriptsDirName(Context context) {
        File storageDir = null;
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

    public static void setLocalContextScope(String val) {
        localContextScope = val;
    }

    public static void setLocalVariableBehavior(String val) {
        localVariableBehavior = val;
    }

    public static void setOutputStream(PrintStream out) {
      if (ruby == null) {
        output = out;
      } else {
        try {
          Method setOutputMethod = ruby.getClass().getMethod("setOutput", PrintStream.class);
          setOutputMethod.invoke(ruby, out);
          Method setErrorMethod = ruby.getClass().getMethod("setError", PrintStream.class);
          setErrorMethod.invoke(ruby, out);
        } catch (IllegalArgumentException e) {
            handleInitException(e);
        } catch (SecurityException e) {
            handleInitException(e);
        } catch (IllegalAccessException e) {
            handleInitException(e);
        } catch (InvocationTargetException e) {
            handleInitException(e);
        } catch (NoSuchMethodException e) {
            handleInitException(e);
        }
      }
    }

}
