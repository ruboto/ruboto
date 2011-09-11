package org.ruboto;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Environment;
import android.util.Log;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import dalvik.system.PathClassLoader;

public class Script {
    private static String scriptsDir = "scripts";
    private static File scriptsDirFile = null;

    private String name = null;
    private static Object ruby;
    private static boolean initialized = false;

    private static String localContextScope = "SINGLETON";
    private static String localVariableBehavior = "TRANSIENT";

    public static final String TAG = "RUBOTO"; // for logging
    private static String JRUBY_VERSION;

    /*************************************************************************************************
     * 
     * Static Methods: ScriptingContainer config
     */

    public static void setLocalContextScope(String val) {
        localContextScope = val;
    }

    public static void setLocalVariableBehavior(String val) {
        localVariableBehavior = val;
    }

    /*************************************************************************************************
     * 
     * Static Methods: JRuby Execution
     */

    public static final FilenameFilter RUBY_FILES = new FilenameFilter() {
        public boolean accept(File dir, String fname) {
            return fname.endsWith(".rb");
        }
    };

	public static synchronized boolean isInitialized() {
		return initialized;
	}

    public static synchronized boolean setUpJRuby(Context appContext) {
        return setUpJRuby(appContext, System.out);
    }

    public static synchronized boolean setUpJRuby(Context appContext, PrintStream out) {
        if (!initialized) {
            Log.d(TAG, "Setting up JRuby runtime");
            System.setProperty("jruby.bytecode.version", "1.5");
            System.setProperty("jruby.interfaces.useProxy", "true");
            System.setProperty("jruby.management.enabled", "false");

            ClassLoader classLoader;
            Class<?> scriptingContainerClass;

            try {
                scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer");
                System.out.println("Found JRuby in this APK");
                classLoader = Script.class.getClassLoader();
            } catch (ClassNotFoundException e1) {
                String packagePath = "org.ruboto.core";
                String apkName = null;
                try {
                    apkName = appContext.getPackageManager().getApplicationInfo(packagePath, 0).sourceDir;
                } catch (PackageManager.NameNotFoundException e) {
                    System.out.println("JRuby not found");
                    return false;
                }

                System.out.println("Found JRuby in platform APK");
                classLoader = new PathClassLoader(apkName, Script.class.getClassLoader());
                try {
                    scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer", true, classLoader);
                } catch (ClassNotFoundException e) {
                    // FIXME(uwe): ScriptingContainer not found in the platform APK...
                    e.printStackTrace();
                    return false;
                }
            }

            try {
                try {
                    JRUBY_VERSION = (String) Class.forName("org.jruby.runtime.Constants", true, classLoader).getDeclaredField("VERSION").get(String.class);
                } catch (java.lang.NoSuchFieldException nsfex) {
                    nsfex.printStackTrace();
                    JRUBY_VERSION = "ERROR";
                }

                Class scopeClass = Class.forName("org.jruby.embed.LocalContextScope", true, scriptingContainerClass.getClassLoader());
                Class behaviorClass = Class.forName("org.jruby.embed.LocalVariableBehavior", true, scriptingContainerClass.getClassLoader());

                ruby = scriptingContainerClass
                         .getConstructor(scopeClass, behaviorClass)
                         .newInstance(Enum.valueOf(scopeClass, localContextScope), 
                                      Enum.valueOf(behaviorClass, localVariableBehavior));

                Class compileModeClass = Class.forName("org.jruby.RubyInstanceConfig$CompileMode", true, classLoader);
                callScriptingContainerMethod(Void.class, "setCompileMode", Enum.valueOf(compileModeClass, "OFF"));

                // callScriptingContainerMethod(Void.class, "setClassLoader", classLoader);
        	    Method setClassLoaderMethod = ruby.getClass().getMethod("setClassLoader", ClassLoader.class);
        	    setClassLoaderMethod.invoke(ruby, classLoader);

                Thread.currentThread().setContextClassLoader(classLoader);

                if (scriptsDir != null) {
                    Log.d(TAG, "Setting JRuby current directory to " + scriptsDir);
                    callScriptingContainerMethod(Void.class, "setCurrentDirectory", scriptsDir);
                }
                if (out != null) {
                    // callScriptingContainerMethod(Void.class, "setOutput", out);
        	        Method setOutputMethod = ruby.getClass().getMethod("setOutput", PrintStream.class);
        	        setOutputMethod.invoke(ruby, out);

                    // callScriptingContainerMethod(Void.class, "setError", out);
        	        Method setErrorMethod = ruby.getClass().getMethod("setError", PrintStream.class);
        	        setErrorMethod.invoke(ruby, out);
                }
                String extraScriptsDir = scriptsDirName(appContext);
                Log.i(TAG, "Checking scripts in " + extraScriptsDir);
                if (configDir(extraScriptsDir)) {
                    Log.i(TAG, "Added extra scripts path: " + extraScriptsDir);
                }
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
            }
        }
        return initialized;
    }

    private static void handleInitException(Exception e) {
        Log.e(TAG, "Exception starting JRuby");
        Log.e(TAG, e.getMessage() != null ? e.getMessage() : e.getClass().getName());
        e.printStackTrace();
        ruby = null;
    }

    @SuppressWarnings("unchecked")
    public static <T> T callScriptingContainerMethod(Class<T> returnType, String methodName, Object... args) {
        Class<?>[] argClasses = new Class[args.length];
        for (int i = 0; i < argClasses.length; i++) {
            argClasses[i] = args[i].getClass();
        }
        try {
        	Method method = ruby.getClass().getMethod(methodName, argClasses);
        	System.out.println("callScriptingContainerMethod: method: " + method);
        	T result = (T) method.invoke(ruby, args);
        	System.out.println("callScriptingContainerMethod: result: " + result);
            return result;
        } catch (RuntimeException re) {
            re.printStackTrace();
        } catch (IllegalAccessException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        } catch (InvocationTargetException e) {
        	try {
                e.printStackTrace();
        	} catch (NullPointerException npe) {
        	}
        } catch (NoSuchMethodException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        return null;
    }

    public static String execute(String code) {
        Object result = exec(code);
        return result != null ? result.toString() : "nil";
// TODO: Why is callMethod returning "main"?
//		return result != null ? callMethod(result, "inspect", String.class) : "null"; 
    }

	public static Object exec(String code) {
        // return callScriptingContainerMethod(Object.class, "runScriptlet", code);
        try {
            Method runScriptletMethod = ruby.getClass().getMethod("runScriptlet", String.class);
            return runScriptletMethod.invoke(ruby, code);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            throw ((RuntimeException) ite.getCause());
        }
	}

    public static void defineGlobalConstant(String name, Object object) {
    	put(name, object);
    }

    public static void put(String name, Object object) {
        // callScriptingContainerMethod(Void.class, "put", name, object);
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
    
    public static void defineGlobalVariable(String name, Object object) {
		defineGlobalConstant(name, object);
    }

    /*************************************************************************************************
    *
    * Static Methods: Scripts Directory
    */
    
    public static void setDir(String dir) {
    	scriptsDir = dir;
    	scriptsDirFile = new File(dir);
        if (ruby != null) {
            Log.d(TAG, "Changing JRuby current directory to " + scriptsDir);
            callScriptingContainerMethod(Void.class, "setCurrentDirectory", scriptsDir);
        }
    }
    
    public static String getDir() {
    	return scriptsDir;
    }

    public static File getDirFile() {
    	return scriptsDirFile;
    }

    public static Boolean configDir(String scriptsDir) {
        setDir(scriptsDir);
        Method getLoadPathsMethod;
        List<String> loadPath = callScriptingContainerMethod(List.class, "getLoadPaths");
        
        if (!loadPath.contains(scriptsDir)) {
            Log.i(TAG, "Adding scripts dir to load path: " + scriptsDir);
            loadPath.add(0, scriptsDir);
            // callScriptingContainerMethod(Void.class, "setLoadPaths", loadPath);
            try {
                Method setLoadPathsMethod = ruby.getClass().getMethod("setLoadPaths", List.class);
                setLoadPathsMethod.invoke(ruby, loadPath);
            } catch (NoSuchMethodException nsme) {
                throw new RuntimeException(nsme);
            } catch (IllegalAccessException iae) {
                throw new RuntimeException(iae);
            } catch (java.lang.reflect.InvocationTargetException ite) {
                throw new RuntimeException(ite);
            }
        }

        if (scriptsDirFile.exists()) {
            Log.i(TAG, "Found extra scripts dir: " + scriptsDir);
            return true;
        } else {
            Log.i(TAG, "Extra scripts dir not present: " + scriptsDir);
            return false;
        }
    }

    private static void copyScripts(String from, File to, AssetManager assets) {
        try {
            byte[] buffer = new byte[8192];
            for (String f : assets.list(from)) {
                File dest = new File(to, f);

                if (dest.exists()) {
                    continue;
                }

                Log.d(TAG, "copying file from " + from + "/" + f + " to " + dest);

                if (assets.list(from + "/" + f).length == 0) {
                    InputStream is = assets.open(from + "/" + f);
                    OutputStream fos = new BufferedOutputStream(new FileOutputStream(dest), 8192);

                    int n;
                    while ((n = is.read(buffer, 0, buffer.length)) != -1) {
                        fos.write(buffer, 0, n);
                    }
                    is.close();
                    fos.close();
                } else {
                    dest.mkdir();
                    copyScripts(from + "/" + f, dest, assets);
                }
            }
        } catch (IOException iox) {
            Log.e(TAG, "error copying scripts", iox);
        }
    }

    public static void copyAssets(Context context, String directory) {
    	File dest = new File(scriptsDirFile.getParentFile(), directory);
		if (dest.exists() || dest.mkdir()) {
            copyScripts(directory, dest, context.getAssets());
		} else {
            throw new RuntimeException("Unable to create scripts directory: " + dest);
		}
    }
    
    private static boolean isDebugBuild(Context context) {
        PackageManager pm = context.getPackageManager();
        PackageInfo pi;
        try {
            pi = pm.getPackageInfo(context.getPackageName(), 0);
            return ((pi.applicationInfo.flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0);
        } catch (NameNotFoundException e) {
            return false;
        }

    }

    private static String scriptsDirName(Context context) {
        File storageDir = null;
        if (isDebugBuild(context)) {

            // FIXME(uwe): Simplify this as soon as we drop support for android-7 or JRuby 1.5.6 or JRuby 1.6.2
            Log.i(TAG, "JRuby VERSION: " + JRUBY_VERSION);
            if (!JRUBY_VERSION.equals("1.5.6") && !JRUBY_VERSION.equals("1.6.2") && android.os.Build.VERSION.SDK_INT >= 8) {
                put("script_context", context);
                storageDir = (File) exec("script_context.getExternalFilesDir(nil)");
            } else {
                storageDir = new File(Environment.getExternalStorageDirectory(), "Android/data/" + context.getPackageName() + "/files");
                Log.e(TAG, "Calculated path to sdcard the old way: " + storageDir);
            }
            // FIXME end

            if (storageDir == null || (!storageDir.exists() && !storageDir.mkdirs())) {
                Log.e(TAG,
                        "Development mode active, but sdcard is not available.  Make sure you have added\n<uses-permission android:name='android.permission.WRITE_EXTERNAL_STORAGE' />\nto your AndroidManifest.xml file.");
                storageDir = context.getFilesDir();
            }
        } else {
            storageDir = context.getFilesDir();
        }
        return storageDir.getAbsolutePath() + "/scripts";
    }

    private static void copyScriptsIfNeeded(Context context) {
        String to = scriptsDirName(context);
		Log.i(TAG, "Checking scripts in " + to);

        /* the if makes sure we only do this the first time */
        if (configDir(to)) {
			Log.i(TAG, "Copying scripts to " + to);
        	copyAssets(context, "scripts");
        }
    }


    /*************************************************************************************************
    *
    * Constructors
    */

    public Script(String name) {
        this.name = name;
    }

    /*************************************************************************************************
     *
     * Attribute Access
     */

    public String getName() {
        return name;
    }

    public File getFile() {
        return new File(getDir(), name);
    }

    public Script setName(String name) {
        this.name = name;
        return this;
    }

    public String getContents() throws IOException {
        InputStream is;
        if (new File(scriptsDir + "/" + name).exists()) {
            is = new java.io.FileInputStream(scriptsDir + "/" + name);
        } else {
            is = getClass().getClassLoader().getResourceAsStream(name);
        }
        BufferedReader buffer = new BufferedReader(new java.io.InputStreamReader(is), 8192);
        StringBuilder source = new StringBuilder();
        while (true) {
            String line = buffer.readLine();
			if (line == null) {
				break;
			}
            source.append(line).append("\n");
        }
        buffer.close();
        return source.toString();
    }

    /*************************************************************************************************
     *
     * Script Actions
     */

    public static String getScriptFilename() {
        return callScriptingContainerMethod(String.class, "getScriptFilename");
    }

    public static void setScriptFilename(String name) {
        callScriptingContainerMethod(Void.class, "setScriptFilename", name);
    }

    public String execute() throws IOException {
    	Script.setScriptFilename(getClass().getClassLoader().getResource(name).getPath());
        return Script.execute(getContents());
    }

	public static void callMethod(Object receiver, String methodName, Object[] args) {
		// callScriptingContainerMethod(Void.class, "callMethod", receiver, methodName, args);
        try {
            Method callMethodMethod = ruby.getClass().getMethod("callMethod", Object.class, String.class, Object[].class);
            callMethodMethod.invoke(ruby, receiver, methodName, args);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            throw (RuntimeException)(ite.getCause());
        }
    }

	public static void callMethod(Object object, String methodName, Object arg) {
		callMethod(object, methodName, new Object[] { arg });
	}

	public static void callMethod(Object object, String methodName) {
		callMethod(object, methodName, new Object[] {});
	}

	@SuppressWarnings("unchecked")
	public static <T> T callMethod(Object receiver, String methodName, Object[] args, Class<T> returnType) {
		// return callScriptingContainerMethod(returnType, "callMethod", receiver, methodName, args, returnType);
        try {
            Method callMethodMethod = ruby.getClass().getMethod("callMethod", Object.class, String.class, Object[].class, Class.class);
            return (T) callMethodMethod.invoke(ruby, receiver, methodName, args, returnType);
        } catch (NoSuchMethodException nsme) {
            throw new RuntimeException(nsme);
        } catch (IllegalAccessException iae) {
            throw new RuntimeException(iae);
        } catch (java.lang.reflect.InvocationTargetException ite) {
            throw (RuntimeException) ite.getCause();
        }
	}

	public static <T> T callMethod(Object receiver, String methodName,
			Object arg, Class<T> returnType) {
		return callMethod(receiver, methodName, new Object[]{arg}, returnType);
	}

	public static <T> T callMethod(Object receiver, String methodName,
			Class<T> returnType) {
		return callMethod(receiver, methodName, new Object[]{}, returnType);
	}

}

