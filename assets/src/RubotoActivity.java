package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private String scriptName;
  private int splash = 0;
  private String remoteVariable = "";
  private Object[] args;
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
    
    if (Script.isInitialized() && (configBundle == null || !configBundle.containsKey("Startup"))) {
        backgroundCreate();
    	finishCreate();
    } else {
      showProgress();
      loadingThread.start();
    }
  }

  private final Handler loadingHandler = new Handler();
  
    private final Thread loadingThread = new Thread() {
        public void run(){
            if (Script.setUpJRuby(RubotoActivity.this)) {
                backgroundCreate();
                loadingHandler.post(loadingComplete);
            } else {
            	// FIXME(uwe): Improve handling of missing Ruboto Core platform.

                // Display nice screen explaining what is happening.
                try {
                    setContentView(Class.forName(getPackageName() + ".R$layout").getField("get_ruboto_core").getInt(null));
                } catch (Exception e) {}
                hideProgress();

                while (!Script.setUpJRuby(RubotoActivity.this)) {
                    try { Thread.sleep(2000); } catch (InterruptedException ie) {}
                }

                // android.os.Looper.prepare();
                runOnUiThread(new Runnable() {
                    public void run() {
                        showProgress();
                    }
                });
                backgroundCreate();
                loadingHandler.post(loadingComplete);
            }
      }
  };

    public void getRubotoCore(View view) {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW).setData(Uri.parse("market://details?id=org.ruboto.core")));
        } catch (android.content.ActivityNotFoundException anfe) {
            try {
                TextView textView = (TextView) findViewById(Class.forName(getPackageName() + ".R$id").getField("text").getInt(null));
                textView.setText("Could not find the Android Market App.  You will have to install Ruboto Core manually.  Bummer!");
            } catch (Exception e) {}
        }
    }
  
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
            if (configBundle.getString("Script") != null) {
                try {
                    new Script(configBundle.getString("Script")).execute();
                } catch(IOException e){
                    e.printStackTrace();
                    ProgressDialog.show(this, "Script failed", "Something bad happened", true, true);
                }
            } else {
                setRemoteVariable(configBundle.getString("Remote Variable"));
                if (configBundle.getBoolean("Define Remote Variable")) {
                    Script.defineGlobalVariable(configBundle.getString("Remote Variable"), this);
                    setRemoteVariable(configBundle.getString("Remote Variable"));
                }
                if (configBundle.getString("Initialize Script") != null) {
                    Script.execute(configBundle.getString("Initialize Script"));
                }
                Script.execute(remoteVariable + "on_create($bundle)");
            }
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

    private void showProgress() {
        if (loadingDialog == null) {
            Log.i("RUBOTO", "Showing progress");
            if (splash == 0) {
        	    try {
            		splash = Class.forName(getPackageName() + ".R$layout").getField("splash").getInt(null);
        		} catch (Exception e) {
        		    splash = -1;
        		}
    		}
            if (splash > 0) {
                requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
                setContentView(splash);
            } else {
                loadingDialog = ProgressDialog.show(this, null, "Starting...", true, false);
            }
        }
    }

    private void hideProgress() {
        if (loadingDialog != null) {
            Log.d("RUBOTO", "Hide progress");
            loadingDialog.dismiss();
            loadingDialog = null;
        }
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
