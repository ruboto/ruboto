package org.ruboto;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

/**
 * This Activity acts as an entry point to the app.  It must initialize the
 * JRuby runtime before restarting its life cycle.  While JRuby is initializing,
 * a progress dialog is shown.  If R.layout.splash is defined, by adding a
 * res/layout/splash.xml file, this layout is displayed instead of the progress
 * dialog.
 */
public class EntryPointActivity extends org.ruboto.RubotoActivity {

    public void onCreate(Bundle bundle) {
        Log.d("EntryPointActivity onCreate:");

        if (JRubyAdapter.isInitialized()) {
            getScriptInfo().setRubyClassName(getClass().getSimpleName());
        } else {
            showSplash();
            finish();
        }

        super.onCreate(bundle);
    }

    private void showSplash() {
        Intent splashIntent = new Intent(this, SplashActivity.class);
        splashIntent.putExtra(Intent.EXTRA_INTENT, futureIntent());
        startActivity(splashIntent);
    }
    
    // The Intent to to call when done. Defaults to calling this Activity again.
    // Override to change.
    protected Intent futureIntent() {
        if (!getIntent().getAction().equals(Intent.ACTION_VIEW)) {
            return new Intent(getIntent()).setAction(Intent.ACTION_VIEW);
        } else {
            return getIntent();
        }
    }
}
