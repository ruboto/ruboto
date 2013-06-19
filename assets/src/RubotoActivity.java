package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    public static final String THEME_KEY = "RUBOTO_THEME";
    private final ScriptInfo scriptInfo = new ScriptInfo();
    Bundle[] args;

    // FIXME(uwe):  What is this for?
    private String remoteVariable = null;

    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = var;
        return this;
    }

    public String getRemoteVariableCall(String call) {
        return (remoteVariable == null ? "" : (remoteVariable + ".")) + call;
    }
    // EMXIF

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

        // Shut this RubotoActivity down if it's not able to restart 
        if (!(this instanceof EntryPointActivity) && !JRubyAdapter.isInitialized()) {
            super.onCreate(bundle);
	        System.out.println("Shutting down stale THE_RUBOTO_CLASS: " + getClass().getName());
            finish();
            return;
        }
				
       if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate(bundle);
            return;
        }
        args = new Bundle[]{bundle};

        // FIXME(uwe):  Deprecated as of Ruboto 0.13.0.  Remove in june 2014 (twelve months).
        Bundle configBundle = getIntent().getBundleExtra("Ruboto Config");
        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
        }
        // EMXIF

        if (getIntent().hasExtra(THEME_KEY)) {
            setTheme(getIntent().getIntExtra(THEME_KEY, 0));
        }
        scriptInfo.setFromIntent(getIntent());

        if (JRubyAdapter.isInitialized() && scriptInfo.isReadyToLoad()) {
    	    ScriptLoader.loadScript(this);
    	    ScriptLoader.callOnCreate(this, (Object[]) args);
        } else {
            super.onCreate(bundle);
        }
    }

    // FIXME(uwe):  What is this for?
    public boolean rubotoAttachable() {
      return true;
    }
    // EMXIF

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
