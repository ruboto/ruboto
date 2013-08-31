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
        Intent splashIntent = new Intent(this, SplashActivity.class);
        splashIntent.putExtra(Intent.EXTRA_INTENT, futureIntent());
        startActivity(splashIntent);
    }
    
    // The Intent to to call when done. Defaults to calling this Activity again.
    // Override to change.
    protected Intent futureIntent() {
        return new Intent(this, this.getClass());
    }
}
