package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS implements RubotoComponent {
THE_CONSTANTS

    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;
    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];
    private String remoteVariable = null;
    private Bundle[] args;
    private Bundle configBundle = null;

    public void setCallbackProc(int id, Object obj) {
        callbackProcs[id] = obj;
    }
	
    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = var;
        return this;
    }

    public String getRemoteVariableCall(String call) {
        return (remoteVariable == null ? "" : (remoteVariable + ".")) + call;
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

    public void setScriptName(String name) {
        scriptName = name;
    }

    /****************************************************************************************
     *
     *  Activity Lifecycle: onCreate
     */

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
	public void onCreate(Object... args) {
	    super.onCreate((Bundle) args[0]);
	}

    @Override
    public void onCreate(Bundle bundle) {
        System.out.println("RubotoActivity onCreate(): " + getClass().getName());
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate(bundle);
            return;
        }
        args = new Bundle[1];
        args[0] = bundle;

        configBundle = getIntent().getBundleExtra("RubotoActivity Config");

        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
            if (configBundle.containsKey("ClassName")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setRubyClassName(configBundle.getString("ClassName"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set class name.");
                }
            }
            if (configBundle.containsKey("Script")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setScriptName(configBundle.getString("Script"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set script name.");
                }
            }
        }

        if (rubyClassName == null && scriptName != null) {
            rubyClassName = Script.toCamelCase(scriptName);
        }
        if (scriptName == null && rubyClassName != null) {
            setScriptName(Script.toSnakeCase(rubyClassName) + ".rb");
        }

        if (JRubyAdapter.isInitialized()) {
            prepareJRuby();
    	    ScriptLoader.loadScript(this, (Object[]) args);
        } else {
            super.onCreate(bundle);
        }
    }

    // TODO(uwe):  Only needed for non-class-based definitions
    // Can be removed if we stop supporting non-class-based definitions
    // This causes JRuby to initialize and takes a while.
    protected void prepareJRuby() {
    	JRubyAdapter.put("$context", this);
    	JRubyAdapter.put("$activity", this);
    	JRubyAdapter.put("$bundle", args[0]);
    }
    // TODO end

    public boolean rubotoAttachable() {
      return true;
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
