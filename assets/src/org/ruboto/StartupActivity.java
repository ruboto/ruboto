package org.ruboto;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

public class StartupActivity extends android.app.Activity {
    private int splash = 0;
    private ProgressDialog loadingDialog;
    private BroadcastReceiver receiver;
    private boolean appStarted = false;

    @Override
    public void onCreate(android.os.Bundle arg0) {
        super.onCreate(arg0);

        if (Script.isInitialized()) {
    	    startRubotoActivity();
    	    return;
        }

        showProgress();

        new Thread() {
            public void run(){
                if (Script.setUpJRuby(StartupActivity.this)) {
                    runOnUiThread(new Runnable(){
                        public void run(){
                            if (loadingDialog != null) {
                                loadingDialog.dismiss();
                                loadingDialog = null;
                            }
	                        startRubotoActivity();
                        }
                    });
                } else {
                    try {
                        setContentView(Class.forName(getPackageName() + ".R$layout").getField("get_ruboto_core").getInt(null));
                    } catch (Exception e) {}
                    if (loadingDialog != null) {
                        loadingDialog.dismiss();
                        loadingDialog = null;
                    }
                }
            }
        }.start();
    }

    public void onDestroy() {
        super.onDestroy();
    }

    public void onPause() {
        super.onPause();
        if (receiver != null) {
    	    unregisterReceiver(receiver);
    	    receiver = null;
        }
    }

    public void onResume() {
        super.onResume();
        if(appStarted) return;
        if (Script.setUpJRuby(StartupActivity.this)) {
            runOnUiThread(new Runnable() {
                public void run() {
                    showProgress();
                    startRubotoActivity();
                }
            });
        } else {
            receiver = new BroadcastReceiver(){
                public void onReceive(Context context, Intent intent) {
                    Log.i(StartupActivity.class.getSimpleName(), "received broadcast: " + intent);
                    startRubotoActivity();
                }
            };
            IntentFilter filter = new IntentFilter(Intent.ACTION_PACKAGE_ADDED);
            filter.addDataScheme("package");
            registerReceiver(receiver, filter);
        }
    }

    // Called when buton is pressed.
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

    public void startRubotoActivity() {
        if(appStarted) return;
        appStarted = true;
        Log.i("RUBOTO", "Starting next activity");
        Intent i = new Intent();
        i.setClassName(getPackageName(), "org.ruboto.RubotoActivity");
        Bundle configBundle = new Bundle();
        configBundle.putString("Script", "startup_activity.rb");
        i.putExtra("RubotoActivity Config", configBundle);
        startActivity(i);
        finish();
    }

    private void showProgress() {
        Log.i("RUBOTO", "Showing progress");
	    try {
    		splash = Class.forName(getPackageName() + ".R$layout").getField("splash").getInt(null);
		} catch (Exception e) {}
        if (splash != 0) {
            requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
            setContentView(splash);
        } else {
            loadingDialog = ProgressDialog.show(this, null, "Loading...", true, false);
        }
    }

}
