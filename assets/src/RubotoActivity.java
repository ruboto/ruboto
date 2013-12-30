package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    public static final String THEME_KEY = "RUBOTO_THEME";

    /**
     * Called at the start of onCreate() to prepare the Activity.
     * @return true if onCreate() should just call super and terminate.
     */
    private boolean preOnCreate(Bundle bundle) {
        System.out.println("RubotoActivity onCreate(): " + getClass().getName() + ", finishing: " + isFinishing());

        if (isFinishing()) return true;

        // Shut this RubotoActivity down if it's not able to restart
        if (this.getClass().getName().equals("org.ruboto.RubotoActivity") && !JRubyAdapter.isInitialized()) {
            super.onCreate(bundle);
            System.out.println("Shutting down stale RubotoActivity: " + getClass().getName());
            finish();
            return true;
        }

        // FIXME(uwe):  Deprecated as of Ruboto 0.13.0.  Remove in june 2014 (twelve months).
        Bundle configBundle = getIntent().getBundleExtra("Ruboto Config");
        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
        }
        // EMXIF

        if (getIntent().hasExtra(THEME_KEY)) {
            setTheme(getIntent().getIntExtra(THEME_KEY, 0));
        }

        scriptInfo.setFromIntent(getIntent());
        return false;
    }

THE_METHODS

}
