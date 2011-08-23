package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Handler;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private String scriptName;
  private int splash = 0;
  private String remoteVariable = "";
  public Object[] args;
  private ProgressDialog loadingDialog; 

THE_CONSTANTS

  private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

  public void setCallbackProc(int id, Object obj) {
    callbackProcs[id] = obj;
  }
	
  public THE_RUBOTO_CLASS setRemoteVariable(String var) {
    remoteVariable = ((var == null) ? "" : (var + "."));
    return this;
  }

  public void setSplash(int a_res){
    splash = a_res;
  }

  public void setScriptName(String name){
    scriptName = name;
  }

  /****************************************************************************************
   * 
   *  Activity Lifecycle: onCreate
   */
	
  @Override
  public void onCreate(android.os.Bundle arg0) {
    args = new Object[1];
    args[0] = arg0;

    android.os.Bundle configBundle = getIntent().getBundleExtra("RubotoActivity Config");

    if (configBundle != null && configBundle.containsKey("Theme")) {
      setTheme(configBundle.getInt("Theme"));
    }

    super.onCreate(arg0);
    
    if (Script.isInitialized()) {
        backgroundCreate();
    	finishCreate();
    } else {
      if (splash == 0) {
        loadingDialog = ProgressDialog.show(this, null, "Loading...", true, false);
      } else {
        requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
        setContentView(splash);
      }
      loadingThread.start();
    }
  }

  private final Handler loadingHandler = new Handler();
  
    private final Thread loadingThread = new Thread() {
        public void run(){
            Script.setUpJRuby(RubotoActivity.this);
            if (Script.isInitialized()) {
                backgroundCreate();
                loadingHandler.post(loadingComplete);
            } else {
            	// FIXME(uwe): Improve handling of missing Ruboto Core platform.
                finish();
            }
      }
  };
  
  private final Runnable loadingComplete = new Runnable(){
    public void run(){
      if (loadingDialog != null) loadingDialog.dismiss();
      finishCreate();
      onStart();
      onResume();
    }
  };

    private void backgroundCreate() {
        Script.put("$activity", this);
        Script.put("$bundle", args[0]);
    }

  private void finishCreate() {
    android.os.Bundle configBundle = getIntent().getBundleExtra("RubotoActivity Config");

    if (configBundle != null) {
      setRemoteVariable(configBundle.getString("Remote Variable"));
      if (configBundle.getBoolean("Define Remote Variable")) {
        Script.defineGlobalVariable(configBundle.getString("Remote Variable"), this);
        setRemoteVariable(configBundle.getString("Remote Variable"));
      }
      if (configBundle.getString("Initialize Script") != null) {
        Script.execute(configBundle.getString("Initialize Script"));
      }
      Script.execute(remoteVariable + "on_create($bundle)");
    } else {
      try {
          new Script(scriptName).execute();
          /* TODO(uwe): Add a way to add callbacks from a class or just forward all calls to the instance
          rubyClassName = this.getClass().getSimpleName();
          if (Script.get(rubyClassName) != null) {
  		    rubyInstance = Script.exec(rubyClassName + ".new");
  		    Script.callMethod(rubyInstance, "on_create", configBundle);
          }
          */
      } catch(IOException e){
        e.printStackTrace();
        ProgressDialog.show(this, "Script failed", "Something bad happened", true, true);
      }
    }
  }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS
}	

