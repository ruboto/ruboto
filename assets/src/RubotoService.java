package THE_PACKAGE;

import org.ruboto.Script;
import org.ruboto.ScriptLoader;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS implements RubotoComponent {
THE_CONSTANTS

    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;
    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];
    public Object[] args;

    public void setCallbackProc(int id, Object obj) {
      callbackProcs[id] = obj;
    }
	
    public android.content.Context getContext() {
        return this;
    }

    public String getRubyClassName() {
        return rubyClassName;
    }

    public void setRubyClassName(String name) {
        rubyClassName = name;
    }

    public void setRubyInstance(Object instance) {
        rubyInstance = instance;
    }

    public String getScriptName() {
        return scriptName;
    }

    public void setScriptName(String name){
        scriptName = name;
    }

    /****************************************************************************************
     *
     *  Service Lifecycle: onCreate
     */

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
	public void onCreate(Object... args) {
	    super.onCreate();
	}

    @Override
    public void onCreate() {
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate();
            return;
        }
	    System.out.println("RubotoService.onCreate()");
        args = new Object[0];

        if (JRubyAdapter.setUpJRuby(this)) {
            // TODO(uwe):  Only needed for non-class-based definitions
            // Can be removed if we stop supporting non-class-based definitions
    	    JRubyAdapter.defineGlobalVariable("$context", this);
    	    JRubyAdapter.defineGlobalVariable("$service", this);
    	    // TODO end

            if (rubyClassName == null && scriptName != null) {
                rubyClassName = Script.toCamelCase(scriptName);
            }
            if (scriptName == null && rubyClassName != null) {
                setScriptName(Script.toSnakeCase(rubyClassName) + ".rb");
            }

            ScriptLoader.loadScript(this);
        } else {
            // FIXME(uwe):  What to do if the Ruboto Core platform cannot be found?
        }
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
