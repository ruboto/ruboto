package org.ruboto;

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

import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.parser.EvalStaticScope;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.scope.ManyVarsDynamicScope;

import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

public class Script {
    private static String scriptsDir = "scripts";
    private static File scriptsDirFile = null;
  
    private String name = null;
    private static Ruby ruby;
    private static DynamicScope scope;
    private static boolean initialized = false;

    private String contents = null;

    public static final String TAG = "RUBOTO"; //for logging

    /*************************************************************************************************
     *
     * Static Methods: JRuby Execution
     */

    public static final FilenameFilter RUBY_FILES = new FilenameFilter() {
        public boolean accept(File dir, String fname) {
            return fname.endsWith(".rb");
        }
    };

    public static boolean initialized() {
        return initialized;
    }

    public static synchronized Ruby setUpJRuby(Context appContext) {
        return setUpJRuby(appContext, System.out);
    }

    public static synchronized Ruby setUpJRuby(Context appContext, PrintStream out) {
        if (ruby == null) {
        	System.setProperty("jruby.interfaces.useProxy", "true");
            RubyInstanceConfig config = new RubyInstanceConfig();
            config.setCompileMode(RubyInstanceConfig.CompileMode.OFF);

            config.setLoader(Script.class.getClassLoader());
            if (scriptsDir != null) config.setCurrentDirectory(scriptsDir);

            if (out != null) {
            	config.setOutput(out);
            	config.setError(out);
            }
            
            /* Set up Ruby environment */
            ruby = Ruby.newInstance(config);

            ThreadContext context = ruby.getCurrentContext();
            DynamicScope currentScope = context.getCurrentScope();
            scope = new ManyVarsDynamicScope(new EvalStaticScope(currentScope.getStaticScope()), currentScope);
            
            copyScriptsIfNeeded(appContext);
            initialized = true;
        }

        return ruby;
    }

    public static String execute(String code) {
        if (!initialized) return null;
        try {
            return exec(code).inspect().asJavaString();
        } catch (RaiseException re) {
            re.printStackTrace(ruby.getErrorStream());
            return null;
        }
    }

    public static IRubyObject exec(String code) throws RaiseException {
        return ruby.evalScriptlet(code, scope);
    }

    public static void defineGlobalConstant(String name, Object object) {
        ruby.defineGlobalConstant(name, JavaUtil.convertJavaToRuby(ruby, object));
    }
    
    public static void defineGlobalVariable(String name, Object object) {
        ruby.getGlobalVariables().set(name, JavaUtil.convertJavaToRuby(ruby, object));
    }
    
    public static Ruby getRuby() {
    	return ruby;
    }

    /*************************************************************************************************
    *
    * Static Methods: Scripts Directory
    */
    
    public static void setDir(String dir) {
    	scriptsDir = dir;
    	scriptsDirFile = new File(dir);
        if (ruby != null) ruby.setCurrentDirectory(scriptsDir);
    }
    
    public static String getDir() {
    	return scriptsDir;
    }

    public static File getDirFile() {
    	return scriptsDirFile;
    }

    public static Boolean configDir(String noSdcard) {
        setDir(noSdcard);

        /* Create directory if it doesn't exist */
        if (!scriptsDirFile.exists()) {
            // TODO check return code
            scriptsDirFile.mkdir();
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
        dest.mkdir();
        copyScripts(directory, dest, context.getAssets());
    }
    
    private static void copyScriptsIfNeeded(Context context) {
        String to = context.getFilesDir().getAbsolutePath() + "/scripts";
        /* the if makes sure we only do this the first time */
        if (configDir(to)) {
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
            if (line == null) break;
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

    public String execute() throws IOException {
        return Script.execute(getContents());
    }
}
