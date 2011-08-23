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

    private String contents = null;

    public static final String TAG = "RUBOTO"; // for logging

    /*************************************************************************************************
     * 
     * Static Methods: JRuby Execution
     */

    public static final FilenameFilter RUBY_FILES = new FilenameFilter() {
        public boolean accept(File dir, String fname) {
            return fname.endsWith(".rb");
        }
    };

	public static boolean isInitialized() {
		return initialized;
	}

    public static synchronized boolean setUpJRuby(Context appContext) {
        return setUpJRuby(appContext, System.out);
    }

    public static synchronized boolean setUpJRuby(Context appContext, PrintStream out) {
        if (ruby == null) {
            Log.d(TAG, "Setting up JRuby runtime");
            System.setProperty("jruby.bytecode.version", "1.5");
            System.setProperty("jruby.interfaces.useProxy", "true");
            System.setProperty("jruby.management.enabled", "false");

            ClassLoader classLoader;
            Class<?> scriptingContainerClass;

            try {
                scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer");
                classLoader = Script.class.getClassLoader();
            } catch (ClassNotFoundException e1) {
                String packagePath = "org.ruboto.core";
                String apkName = null;
                try {
                    apkName = appContext.getPackageManager().getApplicationInfo(packagePath, 0).sourceDir;
                } catch (PackageManager.NameNotFoundException e) {
                    Intent goToMarket = new Intent(Intent.ACTION_VIEW).setData(Uri.parse("market://details?id="
                            + packagePath));
                    appContext.startActivity(goToMarket);
                    return false;
                }

                classLoader = new PathClassLoader(apkName, Script.class.getClassLoader());
                try {
                    scriptingContainerClass = Class.forName("org.jruby.embed.ScriptingContainer", true, classLoader);
                } catch (ClassNotFoundException e) {
                    // FIXME(uwe): ScriptingContainer not found in the platform
                    // APK...
                    e.printStackTrace();
                    return false;
                }
            }

            try {
                ruby = scriptingContainerClass.getConstructor().newInstance();
                Class<?> compileModeClass = Class
                        .forName("org.jruby.RubyInstanceConfig$CompileMode", true, classLoader);
                callScriptingContainerMethod(Void.class, "setCompileMode", compileModeClass.getEnumConstants()[2]);
                callScriptingContainerMethod(Void.class, "setClassLoader", classLoader);
                Thread.currentThread().setContextClassLoader(classLoader);

                if (scriptsDir != null) {
                    Log.d(TAG, "Setting JRuby current directory to " + scriptsDir);
                    callScriptingContainerMethod(Void.class, "setCurrentDirectory", scriptsDir);
                }
                if (out != null) {
                    callScriptingContainerMethod(Void.class, "setOutput", out);
                    callScriptingContainerMethod(Void.class, "setError", out);
                }
                copyScriptsIfNeeded(appContext);
                initialized = true;
                return true;
            } catch (ClassNotFoundException e) {
                // FIXME(uwe): ScriptingContainer not found in the platform APK...
                e.printStackTrace();
            } catch (IllegalArgumentException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (SecurityException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (InstantiationException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (IllegalAccessException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (InvocationTargetException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (NoSuchMethodException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
            return false;
        } else {
            while (!initialized) {
                Log.i(TAG, "Waiting for JRuby runtime to initialize.");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException iex) {
                }
            }
        }
        return true;
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
        try {
        	Object result = exec(code);
			return result != null ? callMethod(result, "inspect", String.class) : "null";
        } catch (RuntimeException re) {
        	// System.err.println(re.getMessage());
			re.printStackTrace();
            return null;
        }
    }

	public static Object exec(String code) {
        return callScriptingContainerMethod(Object.class, "runScriptlet", code);
	}

    public static void defineGlobalConstant(String name, Object object) {
    	put(name, object);
    }

    public static void put(String name, Object object) {
        callScriptingContainerMethod(Void.class, "put", name, object);
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

    public static Boolean configDir(String noSdcard) {
        setDir(noSdcard);
		Method getLoadPathsMethod;
        List<String> loadPath = callScriptingContainerMethod(List.class, "getLoadPaths");
        
        if (!loadPath.contains(noSdcard)) {
            Log.i(TAG, "Adding scripts dir to load path: " + noSdcard);
            List<String> paths = loadPath;
            paths.add(noSdcard);
            callScriptingContainerMethod(Void.class, "setLoadPaths", paths);
        }

        /* Create directory if it doesn't exist */
        if (!scriptsDirFile.exists()) {
            boolean dirCreatedOk = scriptsDirFile.mkdirs();
            if (!dirCreatedOk) {
                throw new RuntimeException("Unable to create script directory");
            }
            return true;
        }

        return false;
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
		File toFile = null;
        if (isDebugBuild(context)) {

        	// FIXME(uwe): Simplify this as soon as we drop support for android-7 or JRuby 1.5.6 or JRuby 1.6.2
            // Log.i(TAG, "JRuby VERSION: " + org.jruby.runtime.Constants.VERSION);
            // if (!org.jruby.runtime.Constants.VERSION.equals("1.5.6") && !org.jruby.runtime.Constants.VERSION.equals("1.6.2") && android.os.Build.VERSION.SDK_INT >= 8) {
            //     ruby.put("script_context", context);
            //     toFile = (File) exec("script_context.getExternalFilesDir(nil)");
            // } else {
                toFile = new File(Environment.getExternalStorageDirectory(), "Android/data/" + context.getPackageName() + "/files");
                Log.e(TAG, "Calculated path to sdcard the old way: " + toFile);
            // }
            // FIXME end

	        if (toFile == null || (!toFile.exists() && !toFile.mkdirs())) {
		    	Log.e(TAG,
                        "Development mode active, but sdcard is not available.  Make sure you have added\n<uses-permission android:name='android.permission.WRITE_EXTERNAL_STORAGE' />\nto your AndroidManifest.xml file.");
	            toFile = context.getFilesDir();
            }
		} else {
            toFile = context.getFilesDir();
        }
		String to = toFile.getAbsolutePath() + "/scripts";
		return to;
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
        this(name, null);
    }

    public Script(String name, String contents) {
        this.name = name;
        this.contents = contents;
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
        // TODO: Other states possible
        return this;
    }

    public String getContents() throws IOException {
        BufferedReader buffer = new BufferedReader(new FileReader(getFile()), 8192);
        StringBuilder source = new StringBuilder();
        while (true) {
            String line = buffer.readLine();
			if (line == null) {
				break;
			}
            source.append(line).append("\n");
        }
        buffer.close();
        contents = source.toString();
        return contents;
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
    	setScriptFilename(name);
        return Script.execute(getContents());
    }

	public static void callMethod(Object object, String methodName, Object[] objects) {
		callScriptingContainerMethod(Void.class, "callMethod", object, methodName, objects);
    }

	public static void callMethod(Object object, String methodName, Object arg) {
		callMethod(object, methodName, new Object[] { arg });
	}

	public static void callMethod(Object object, String methodName) {
		callMethod(object, methodName, new Object[] {});
	}

	@SuppressWarnings("unchecked")
	public static <T> T callMethod(Object receiver, String methodName, Object[] args, Class<T> returnType) {
		return callScriptingContainerMethod(returnType, "callMethod", receiver, methodName, args, returnType);
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

