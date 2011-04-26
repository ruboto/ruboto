package THE_PACKAGE;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;
import org.ruboto.Script;
import java.io.IOException;
import android.app.ProgressDialog;
import android.os.Handler;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private Ruby __ruby__;
  private String scriptName;
  private int splash = 0;
  private String remoteVariable = "";
  public Object[] args;
  private ProgressDialog loadingDialog; 

THE_CONSTANTS
  private IRubyObject[] callbackProcs = new IRubyObject[CONSTANTS_COUNT];

  private Ruby getRuby() {
    if (__ruby__ == null) {
        __ruby__ = Script.getRuby();

        if (__ruby__ == null) {
          Script.setUpJRuby(this);
          __ruby__ = Script.getRuby();
        }
    }

    return __ruby__;
  }

  public void setCallbackProc(int id, IRubyObject obj) {
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

    super.onCreate(arg0);
    
    if (Script.getRuby() != null) {
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
        backgroundCreate();
        loadingHandler.post(loadingComplete);
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
    getRuby();
    Script.defineGlobalVariable("$activity", this);
    Script.defineGlobalVariable("$bundle", args[0]);
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

