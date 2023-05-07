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
    private static final int INSTALL_REQUEST_CODE = 4242;

    public void onCreate(Bundle bundle) {
        Log.d("SplashActivity onCreate:");
        try {
            splash = Class.forName(getPackageName() + ".R$layout").getField("splash").getInt(null);
        } catch (Exception e) {
            splash = -1;
        }
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

    public void onDestroy() {
        Log.d("SplashActivity onDestroy: ");
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

    private void startUserActivity() {
        if (getIntent().hasExtra(Intent.EXTRA_INTENT)) {
            startActivity((Intent)getIntent().getParcelableExtra(Intent.EXTRA_INTENT));
            finish();
        }
    }

}
