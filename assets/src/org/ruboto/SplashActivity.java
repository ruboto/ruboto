package org.ruboto;

import android.app.Activity;
import android.app.DownloadManager;
import android.app.DownloadManager.Query;
import android.app.DownloadManager.Request;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.DialogInterface.OnCancelListener;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;


public class SplashActivity extends Activity {
    private int splash = 0;
    private ProgressDialog loadingDialog;
    private boolean dialogCancelled = false;
    private BroadcastReceiver receiver;
    private long enqueue;
    java.io.File localFile;
    private static final int INSTALL_REQUEST_CODE = 4242;

    public void onCreate(Bundle bundle) {
        Log.d("SplashActivity onCreate:");
        localFile = new java.io.File(getFilesDir(), RUBOTO_APK);
        try {
            splash = Class.forName(getPackageName() + ".R$layout").getField("splash").getInt(null);
        } catch (Exception e) {
            splash = -1;
        }
        if (!JRubyAdapter.isInitialized()) {
            initJRuby(true);
        }
        super.onCreate(bundle);
    }

    public void onResume() {
        Log.d("onResume: ");
        if (!JRubyAdapter.isInitialized() && receiver == null) {
            registerPackageInstallReceiver();
        }
        super.onResume();
    }
    
    public void onPause() {
        Log.d("onPause: ");
        if (receiver != null) {
            unregisterReceiver(receiver);
            receiver = null;
        }
        super.onPause();
    }

    public void onDestroy() {
        Log.d("onDestroy: ");
        super.onDestroy();
        if (dialogCancelled) {
            System.runFinalizersOnExit(true);
            System.exit(0);
        }
    }
    
    private void initJRuby(final boolean firstTime) {
        showProgress();
        new Thread(new Runnable() {
            public void run() {
                final boolean jrubyOk = JRubyAdapter.setUpJRuby(SplashActivity.this);
                if (jrubyOk) {
                    Log.d("onResume: JRuby OK");
                    startUserActivity();
                } else {
                    registerPackageInstallReceiver();
                    runOnUiThread(new Runnable() {
                        public void run() {
                            if (localFile.exists()) {
                                installDownload();
                            } else {
                                if (firstTime) {
                                    Log.d("onResume: Checking JRuby - IN UI thread");
                                    try {
                                        setContentView(Class.forName(getPackageName() + ".R$layout").getField("get_ruboto_core").getInt(null));
                                        if (hasInternetPermission()) {
                                            getRubotoCore(null);
                                            return;
                                        }
                                    } catch (Exception e) {
                                    }
                                } else {
                                    Toast.makeText(SplashActivity.this,"Failed to initialize Ruboto Core.",Toast.LENGTH_LONG).show();
                                    try {
                                        TextView textView = (TextView) findViewById(Class.forName(getPackageName() + ".R$id").getField("text").getInt(null));
                                        textView.setText("Woops!  Ruboto Core was installed, but it failed to initialize properly!  I am not sure how to proceed from here.  If you can, please file an error report at http://ruboto.org/");
                                    } catch (Exception e) {
                                    }
                                }
                            }
                            hideProgress();
                        }
                    });
                }
            }
        }).start();
    }

    private static final String RUBOTO_APK = "RubotoCore-release.apk";
    private static final String RUBOTO_URL = "http://ruboto.org/downloads/" + RUBOTO_APK;

    // Called when the button is pressed.
    public void getRubotoCore(View view) {
        try {
            if (hasInternetPermission() && canInstallFromUnknownSources()) {
                if (enqueue <= 0) {
                    DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                    Request request = new Request(Uri.parse(RUBOTO_URL));
                    enqueue = dm.enqueue(request);
                    hideProgress();
                    showDownloadProgress("Downloading RubotoCore...");
                    new Thread(new Runnable() {
                        public void run() {
                            while (loadingDialog != null && enqueue > 0) {
                                // FIXME(uwe):  Also set total bytes and bytes downloaded.
                                loadingDialog.setProgress(getProgressPercentage());
                                try {
                                    Thread.sleep(1000);
                                } catch (InterruptedException ie) {
                                    Log.e("Interupted!");
                                }
                            }
                        }
                    }).start();
                }
                return;
            } else {
                Log.e("Permission missing for direct download: Internet: " +
                        hasInternetPermission() + ", non-market install: " +
                        canInstallFromUnknownSources());
            }
        } catch (Exception e) {
            Log.e("Exception in direct RubotoCore download: " + e);
            e.printStackTrace();
        }
        try {
            Log.i("Download RubotoCore using the market");
            startActivity(new Intent(Intent.ACTION_VIEW).setData(Uri.parse("market://details?id=org.ruboto.core")));
        } catch (android.content.ActivityNotFoundException anfe) {
            Log.e("Exception in market RubotoCore download: " + anfe);
            Log.i("Download RubotoCore using the download manager");
            Intent intent = new Intent(android.content.Intent.ACTION_VIEW, Uri.parse(RUBOTO_URL));
            startActivity(intent);
        }
    }

    private void showProgress() {
        if (loadingDialog == null) {
            if (splash > 0) {
                Log.i("Showing splash");
                requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
                setContentView(splash);
            } else {
                Log.i("Showing progress");
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

    private void showDownloadProgress(String message) {
        if (loadingDialog == null) {
            if (splash > 0) {
                Log.i("Showing splash");
                requestWindowFeature(android.view.Window.FEATURE_NO_TITLE);
                setContentView(splash);
            } else {
                Log.i("Showing progress");
                loadingDialog = new ProgressDialog(this);
                loadingDialog.setTitle(null);
                loadingDialog.setMessage(message);
                loadingDialog.setIndeterminate(false);
                loadingDialog.setMax(100);
                loadingDialog.setProgressStyle(android.app.ProgressDialog.STYLE_HORIZONTAL);
                loadingDialog.setCancelable(true);
                loadingDialog.setCanceledOnTouchOutside(false);
                loadingDialog.setOnCancelListener(new OnCancelListener() {
                    public void onCancel(DialogInterface dialog) {
                        dialogCancelled = true;
                        finish();
                    }
                });
                loadingDialog.show();
            }
        } else {
            loadingDialog.setMessage(message);
        }
    }

    private void hideProgress() {
        if (loadingDialog != null) {
            Log.d("Hide progress");
            loadingDialog.dismiss();
            loadingDialog = null;
        }
    }

    private void registerPackageInstallReceiver() {
        receiver = new BroadcastReceiver(){
            public void onReceive(Context context, Intent intent) {
                Log.d("Received intent: " + intent + " (" + intent.getExtras() + ")");
                if (DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(intent.getAction())) {
                    long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
                    if (downloadId == enqueue) {
                        if (localFile.exists()) {
                            return;
                        }
                        Query query = new Query();
                        query.setFilterById(enqueue);
                        DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                        Cursor c = dm.query(query);
                        if (c.moveToFirst()) {
                            hideProgress();
                            int status = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_STATUS));
                            if (DownloadManager.STATUS_SUCCESSFUL == status) {
                                storeDownload(dm, downloadId);
                                installDownload();
                            } else {
                                int reason = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_REASON));
                                Toast.makeText(context,"Download failed (" + status + "): " + reason, Toast.LENGTH_LONG).show();
                            }
                        } else {
                            Toast.makeText(context,"Download diappeared!", Toast.LENGTH_LONG).show();
                        }
                        c.close();
                    }
                } else if (Intent.ACTION_PACKAGE_ADDED.equals(intent.getAction())) {
                    if (intent.getData().toString().equals("package:org.ruboto.core")) {
                        Toast.makeText(context,"Ruboto Core is now installed.",Toast.LENGTH_LONG).show();
                        deleteFile(RUBOTO_APK);
                        if (receiver != null) {
                            unregisterReceiver(receiver);
                            receiver = null;
                        }
                        initJRuby(false);
                    } else {
                        Toast.makeText(context,"Installed: " + intent.getData().toString(),Toast.LENGTH_LONG).show();
                    }
                }
            }
            };
        IntentFilter filter = new IntentFilter(Intent.ACTION_PACKAGE_ADDED);
        filter.addDataScheme("package");
        registerReceiver(receiver, filter);
        IntentFilter download_filter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
        registerReceiver(receiver, download_filter);
    }

    private void storeDownload(DownloadManager dm, long downloadId) {
        try {
            android.os.ParcelFileDescriptor file = dm.openDownloadedFile(downloadId);
            java.io.InputStream fileStream = new java.io.FileInputStream(file.getFileDescriptor());
            java.io.FileOutputStream fos = openFileOutput(RUBOTO_APK, MODE_WORLD_READABLE);
            byte[] buffer = new byte[1024];
            int length;
            while((length = fileStream.read(buffer)) > 0) {
                fos.write(buffer, 0, length);
            }
            fos.flush();
            fileStream.close();
            fos.close();
            dm.remove(downloadId);
            enqueue = 0;
        } catch (java.io.IOException ioe) {
            Log.e("Exception copying RubotoCore: " + ioe);
            Toast.makeText(this, "Exception copying RubotoCore: " + ioe, Toast.LENGTH_LONG).show();
        }
    }

    // FIXME(uwe): Remove when we stop supporting Android < 4.0.3
    private void installDownload() {
        if (android.os.Build.VERSION.SDK_INT < 15) {
            installDownload_10();
        } else {
            installDownload_15();
        }
    }
    // EMXIF

    // FIXME(uwe): Remove when we stop supporting Android < 4.0.3
    private void installDownload_10() {
        Uri uri = Uri.fromFile(localFile);
        SplashActivity.this.grantUriPermission("com.android.packageinstaller", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
        Intent installIntent = new Intent(Intent.ACTION_VIEW);
        installIntent.setDataAndType(uri, "application/vnd.android.package-archive");
        installIntent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
        startActivityForResult(installIntent, INSTALL_REQUEST_CODE);
    }
    // EMXIF

    // FIXME(uwe):  Use constants when we stop suporting Android < 4.0.3
    private void installDownload_15() {
        Uri uri = Uri.fromFile(localFile);
        SplashActivity.this.grantUriPermission("com.android.packageinstaller", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION);
        Intent installIntent = new Intent("android.intent.action.INSTALL_PACKAGE"); // Intent.ACTION_INSTALL_PACKAGE
        installIntent.setDataAndType(uri, "application/vnd.android.package-archive");
        installIntent.setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_READ_URI_PERMISSION);
        // FIXME(uwe): Remove when we stop supporting Android api level < 16
        installIntent.putExtra("android.intent.extra.ALLOW_REPLACE", true); // Intent.EXTRA_ALLOW_REPLACE
        // EMXIF
        installIntent.putExtra("android.intent.extra.INSTALLER_PACKAGE_NAME", getPackageName()); // Intent.EXTRA_INSTALLER_PACKAGE_NAME
        installIntent.putExtra("android.intent.extra.NOT_UNKNOWN_SOURCE", true); // Intent.EXTRA_NOT_UNKNOWN_SOURCE
        installIntent.putExtra("android.intent.extra.RETURN_RESULT", true); // Intent.EXTRA_RETURN_RESULT
        startActivityForResult(installIntent, INSTALL_REQUEST_CODE);
    }
    // EMXIF

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

    private boolean hasInternetPermission() {
        String permission = "android.permission.INTERNET";
        int res = checkCallingOrSelfPermission(permission);
        return (res == PackageManager.PERMISSION_GRANTED);
    }

    private boolean canInstallFromUnknownSources() {
        // FIXME(uwe): Use Settings.Global when we stop supporting Android api level < 17
        // return Settings.Global.getInt(getContentResolver(), Settings.Global.INSTALL_NON_MARKET_APPS, 0) == 1;
        // EMXIF

        return Settings.Secure.getInt(getContentResolver(), Settings.Secure.INSTALL_NON_MARKET_APPS, 0) == 1;
    }

    // Get the downloaded percent
    private int getProgressPercentage() {
        int downloadedBytesSoFar = 0, totalBytes = 0, percentage = 0;
        DownloadManager dm = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
        try {
            Cursor c = dm.query(new DownloadManager.Query().setFilterById(enqueue));
            if (c.moveToFirst()) {
                int soFarIndex =c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR);
                downloadedBytesSoFar = (int) c.getLong(soFarIndex);
                int totalSizeIndex = c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES);
                totalBytes = (int) c.getLong(totalSizeIndex);
            }
            System.out.println("PERCEN ------" + downloadedBytesSoFar
                               + " ------ " + totalBytes + "****" + percentage);
            percentage = (downloadedBytesSoFar * 100 / totalBytes);
            System.out.println("percentage % " + percentage);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return percentage;
    }

    private void startUserActivity() {
        if (getIntent().hasExtra(Intent.EXTRA_INTENT)) {
            startActivity((Intent)getIntent().getParcelableExtra(Intent.EXTRA_INTENT));
            finish();
        }
    }

}
