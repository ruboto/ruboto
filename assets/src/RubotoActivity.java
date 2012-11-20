package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private final ScriptInfo scriptInfo = new ScriptInfo();
    private String remoteVariable = null;
    Bundle[] args;
    private Bundle configBundle = null;

    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = var;
        return this;
    }

    public String getRemoteVariableCall(String call) {
        return (remoteVariable == null ? "" : (remoteVariable + ".")) + call;
    }

    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    /****************************************************************************************
     *
     *  Activity Lifecycle: onCreate
     */
    @Override
    public void onCreate(Bundle bundle) {
        System.out.println("THE_RUBOTO_CLASS onCreate(): " + getClass().getName());
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
                if (this.getClass().getName() == THE_RUBOTO_CLASS.class.getName()) {
                    scriptInfo.setRubyClassName(configBundle.getString("ClassName"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set class name.");
                }
            }
            if (configBundle.containsKey("Script")) {
                if (this.getClass().getName() == THE_RUBOTO_CLASS.class.getName()) {
                    scriptInfo.setScriptName(configBundle.getString("Script"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set script name.");
                }
            }
        }

        if (JRubyAdapter.isInitialized()) {
    	    ScriptLoader.loadScript(this, (Object[]) args);
        } else {
            super.onCreate(bundle);
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
