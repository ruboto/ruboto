package org.ruboto;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

/**
 * This Activity acts as an entry point to the app.  It must initialize the
 * JRuby runtime before continuing its life cycle.
 * While JRuby is initializing, a progress dialog is shown.
 * If R.layout.splash is defined, by adding a res/layout/splash.xml file,
 * this layout is displayed instead of the progress dialog.
 */
public class EntryPointActivity extends org.ruboto.RubotoActivity {
    private static final int INSTALL_REQUEST_CODE = 4242;
    private static final String RUBOTO_APK = "RubotoCore-release.apk";
    
    public void onCreate(Bundle bundle) {
        Log.d("EntryPointActivity onCreate:");
	getScriptInfo().setRubyClassName(getClass().getSimpleName());

        if (!JRubyAdapter.isInitialized()) {
	    showSplash();
	    finish();
	}
	super.onCreate(bundle);
    }

    public void onResume() {
        Log.d("onResume: ");

        if(getScriptInfo().isLoaded()) {
            Log.d("onResume: App already started!");
            super.onResume();
            return;
        }

        Log.d("onResume: Checking JRuby");
        if (JRubyAdapter.isInitialized()) {
            Log.d("Already initialized");
    	    fireRubotoActivity();
        } else {
            Log.d("Not initialized");
	    showSplash();
	    finish();
        }
	super.onResume();
    }

    public void onPause() {
        Log.d("onPause: ");
        super.onPause();
    }

    public void onDestroy() {
        Log.d("onDestroy: ");
        super.onDestroy();
    }


    protected void fireRubotoActivity() {
        if(getScriptInfo().isLoaded()) return;
        Log.i("Starting activity");
        ScriptLoader.loadScript(this);
        runOnUiThread(new Runnable() {
		public void run() {
		    ScriptLoader.callOnCreate(EntryPointActivity.this, args[0]);
		    onStart();
		    onResume();
		}
	    });
    }

    private void showSplash() {
	Intent splashIntent = new Intent(EntryPointActivity.this, SplashActivity.class);
	startActivity(splashIntent);
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d("onActivityResult: " + requestCode + ", " + resultCode + ", " + data);
        Log.d("onActivityResult: " + INSTALL_REQUEST_CODE + ", " + RESULT_OK + ", " + RESULT_CANCELED);
        if (requestCode == INSTALL_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                Log.d("onActivityResult: Install OK.");
            } else if (resultCode == RESULT_CANCELED) {
                Log.d("onActivityResult: Install canceled.");
                // FIXME(uwe): Maybe show a dialog explaining that RubotoCore is needed and try again?
                deleteFile(RUBOTO_APK);
                if (!JRubyAdapter.isInitialized()) {
                    finish();
                }
                // EMXIF
            } else {
                Log.e("onActivityResult: resultCode: " + resultCode);
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

}
