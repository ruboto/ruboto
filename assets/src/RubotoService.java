package THE_PACKAGE;

import org.ruboto.Script;
import org.ruboto.ScriptLoader;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private final ScriptInfo scriptInfo = new ScriptInfo();

    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    /****************************************************************************************
     *
     *  Service Lifecycle: onCreate
     */
    @Override
    public void onCreate() {
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate();
            return;
        }
	    System.out.println("RubotoService.onCreate()");

        if (JRubyAdapter.setUpJRuby(this)) {
            ScriptLoader.loadScript(this);
        } else {
            // FIXME(uwe):  What to do if the Ruboto Core platform cannot be found?
        }
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
