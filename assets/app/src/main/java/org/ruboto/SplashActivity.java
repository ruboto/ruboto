package org.ruboto;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;


public class SplashActivity extends Activity {
    private int splash = 0;
    private ProgressDialog loadingDialog;
    private boolean dialogCancelled = false;
    // Set on the JRuby start-up thread, read on the UI thread.
    private volatile boolean userActivityStarted = false;
    private static SplashActivity current;
    private static final int INSTALL_REQUEST_CODE = 4242;

    public void onCreate(Bundle bundle) {
        Log.d("SplashActivity onCreate:");
        try {
            splash = Class.forName(getPackageName() + ".R$layout").getField("splash").getInt(null);
        } catch (Exception e) {
            splash = -1;
        }
        current = this;
        requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
        if (!JRubyAdapter.isInitialized()) {
            initJRuby(true);
        }
        super.onCreate(bundle);
    }

    public void onResume() {
        Log.d("SplashActivity onResume: ");
        super.onResume();
    }

    public void onPause() {
        Log.d("SplashActivity onPause: ");
        super.onPause();
    }

    // Called by EntryPointActivity once the user Activity exists.  Finishing
    // the splash any earlier (right after startActivity, or through
    // noHistory while the screen is off) leaves the process without an
    // Activity until the new one attaches.  Devices that keep no background
    // processes kill such an "empty" process at once, which turns the launch
    // into an endless restart loop.
    static void userActivityCreated() {
        SplashActivity splash = current;
        if (splash != null && splash.userActivityStarted) {
            splash.finish();
        }
    }

    // Fallback for user Activities that are not EntryPointActivities: once
    // the splash is stopped after starting them, they cover it.
    public void onStop() {
        super.onStop();
        if (userActivityStarted) {
            finish();
        }
    }

    public void onDestroy() {
        Log.d("SplashActivity onDestroy: ");
        if (current == this) {
            current = null;
        }
        super.onDestroy();
        if (dialogCancelled) {
            System.runFinalizersOnExit(true);
            System.exit(0);
        } else {
            hideProgress();
        }
    }

    private void initJRuby(final boolean firstTime) {
        showProgress();
        new Thread(new Runnable() {
            public void run() {
                final boolean jrubyOk = JRubyAdapter.setUpJRuby(SplashActivity.this);
                if (jrubyOk) {
                    Log.d("SplashActivity onResume: JRuby OK");
                    preloadUserActivityScript();
                    startUserActivity();
                } else {
                    runOnUiThread(new Runnable() {
                        public void run() {
                            Toast.makeText(SplashActivity.this, "Failed to initialize Ruboto Core.", Toast.LENGTH_LONG).show();
                            try {
                                TextView textView = (TextView) findViewById(android.R.id.text1);
                                textView.setText("Woops!  Ruboto failed to initialize properly!  I am not sure how to proceed from here.  If you can, please file an error report at http://ruboto.org/");
                            } catch (Exception e) {
                            }
                            hideProgress();
                        }
                    });
                }
            }
        }).start();
    }

    private void showProgress() {
        if (loadingDialog == null) {
            if (splash > 0) {
                Log.i("SplashActivity Showing splash");
                setContentView(splash);
            } else {
                Log.i("SplashActivity Showing progress");
                loadingDialog = ProgressDialog.show(this, null, "Starting...", true, true);
                loadingDialog.setCanceledOnTouchOutside(false);
                loadingDialog.setOnCancelListener(new OnCancelListener() {
                    public void onCancel(DialogInterface dialog) {
                        dialogCancelled = true;
                        finish();
                    }
                });
            }
        }
    }

    private void hideProgress() {
        if (loadingDialog != null) {
            Log.d("SplashActivity Hide progress");
            loadingDialog.dismiss();
            loadingDialog = null;
        }
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d("SplashActivity onActivityResult: " + requestCode + ", " + resultCode + ", " + data);
        Log.d("SplashActivity onActivityResult: " + INSTALL_REQUEST_CODE + ", " + RESULT_OK + ", " + RESULT_CANCELED);
        if (requestCode == INSTALL_REQUEST_CODE) {
            if (resultCode == RESULT_OK) {
                Log.d("SplashActivity onActivityResult: Install OK.");
            } else if (resultCode == RESULT_CANCELED) {
                Log.d("SplashActivity onActivityResult: Install canceled.");
                if (!JRubyAdapter.isInitialized()) {
                    finish();
                }
                // EMXIF
            } else {
                Log.e("SplashActivity onActivityResult: resultCode: " + resultCode);
            }
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    // Evaluate the script for the Activity we are about to start, while we are
    // still on the background thread and the splash is covering for us.  Doing it
    // in that Activity's onCreate blocks the UI thread past the input dispatcher's
    // 5 second focus timeout and the app is killed before it draws.
    private void preloadUserActivityScript() {
        Intent userIntent = (Intent) getIntent().getParcelableExtra(Intent.EXTRA_INTENT);
        if (userIntent != null && userIntent.getComponent() != null) {
            ScriptLoader.preloadScript(userIntent.getComponent().getClassName());
        }
    }

    private void startUserActivity() {
        if (getIntent().hasExtra(Intent.EXTRA_INTENT)) {
            userActivityStarted = true;
            startActivity((Intent)getIntent().getParcelableExtra(Intent.EXTRA_INTENT));
        }
    }

}
