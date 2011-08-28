package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private String remoteVariable = "";
    private Object[] args;
    private Bundle configBundle;

THE_CONSTANTS

    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

    public void setCallbackProc(int id, Object obj) {
        callbackProcs[id] = obj;
    }
	
    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = ((var == null) ? "" : (var + "."));
        return this;
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
    
        if (Script.isInitialized()) {
            prepareJRuby();
    	    loadScript();
        }
    }

    // This causes JRuby to initialize and takes while
    protected void prepareJRuby() {
        Script.put("$activity", this);
        Script.put("$bundle", args[0]);
    }

    protected void loadScript() {
        try {
            if (scriptName != null) {
                new Script(scriptName).execute();
            } else if (configBundle != null && configBundle.getString("Remote Variable") != null) {
                setRemoteVariable(configBundle.getString("Remote Variable"));
                if (configBundle.getBoolean("Define Remote Variable")) {
                    Script.defineGlobalVariable(remoteVariable, this);
                }
                if (configBundle.getString("Initialize Script") != null) {
                    Script.execute(configBundle.getString("Initialize Script"));
                }
                Script.execute(remoteVariable + "on_create($bundle)");
            }
        } catch(IOException e){
            e.printStackTrace();
            ProgressDialog.show(this, "Script failed", "Something bad happened", true, true);
        }
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
