package org.ruboto;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.exceptions.RaiseException;
import org.jruby.javasupport.JavaUtil;
import org.jruby.parser.EvalStaticScope;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.scope.ManyVarsDynamicScope;

import android.os.Environment;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.BasicResponseHandler;
import org.apache.http.impl.client.DefaultHttpClient;

public class Script {
    private static String scriptsDir = null;
    private static File scriptsDirFile = null;
  
    private String name = null;
    private static Ruby ruby;
    private static DynamicScope scope;
    private static boolean initialized = false;

    private String contents = null;

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

    public static synchronized Ruby setUpJRuby(PrintStream out) {
        if (ruby == null) {
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
            
            initialized = true;
        }

        return ruby;
    }

    public static String execute(String code) {
        if (!initialized) return null;
        try {
            return ruby.evalScriptlet(code, scope).inspect().asJavaString();
        } catch (RaiseException re) {
            re.printStackTrace(ruby.getErrorStream());
            return null;
        }
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
        File file = getFile();

        if (contents == null && !file.exists()) {
            state = STATE_EMPTY;
            this.contents = "";
        } else if (contents == null && file.exists()) {
            state = STATE_ON_DISK;
        } else if (contents != null) {
            state = STATE_IN_MEMORY_DIRTY;
        } else {
            // TODO: Exception
        }
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
        state = STATE_IN_MEMORY_DIRTY;
        // TODO: Other states possible
        return this;
    }

    public String getContents() throws IOException {
        if (state == STATE_ON_DISK) {
            BufferedReader buffer = new BufferedReader(new FileReader(getFile()));
            StringBuilder source = new StringBuilder();
            while (true) {
                String line = buffer.readLine();
                if (line == null) break;
                source.append(line).append("\n");
            }
            buffer.close();
            contents = source.toString();
            state = STATE_IN_MEMORY;
        }
        return contents;
    }

    /*************************************************************************************************
     *
     * Script Actions
     */

    public String execute() throws IOException {
        return Script.execute(getContents());
    }

    public Integer getState() {
        return state;
    }
}
