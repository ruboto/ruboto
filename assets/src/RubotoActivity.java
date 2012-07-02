package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private String remoteVariable = null;
    private Object[] args;
    private Bundle configBundle = null;
    private Object rubyInstance;

THE_CONSTANTS

    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

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

    public void setScriptName(String name) {
        scriptName = name;
    }

    /****************************************************************************************
     *
     *  Activity Lifecycle: onCreate
     */
	
    @Override
    public void onCreate(Bundle bundle) {
        args = new Object[1];
        args[0] = bundle;

        configBundle = getIntent().getBundleExtra("RubotoActivity Config");

        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
            if (configBundle.containsKey("Script")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setScriptName(configBundle.getString("Script"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set script name.");
                }
            }
        }

        super.onCreate(bundle);
    
        if (JRubyAdapter.isInitialized()) {
            prepareJRuby();
    	    loadScript();
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

    protected void loadScript() {
        try {
            if (scriptName != null) {
                String rubyClassName = Script.toCamelCase(scriptName);
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = JRubyAdapter.get(rubyClassName);
                if (rubyClass == null) {
                    System.out.println("Loading script: " + scriptName);
                    JRubyAdapter.exec(new Script(scriptName).getContents());
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
                if (rubyClass != null) {
                    System.out.println("Instanciating Ruby class: " + rubyClassName);
                    rubyInstance = JRubyAdapter.callMethod(rubyClass, "new", this, Object.class);
                    JRubyAdapter.callMethod(rubyInstance, "on_create", args[0]);
                }
            } else if (configBundle != null) {
                // TODO: Why doesn't this work?
                // JRubyAdapter.callMethod(this, "initialize_ruboto");
            	JRubyAdapter.execute("$activity.initialize_ruboto");
                // TODO: Why doesn't this work?
                // JRubyAdapter.callMethod(this, "on_create", args[0]);
            	JRubyAdapter.execute("$activity.on_create($bundle)");
            }
        } catch(IOException e){
            e.printStackTrace();
            ProgressDialog.show(this, "Script failed", "Something bad happened", true, true);
        }
    }

    public boolean rubotoAttachable() {
      return true;
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
