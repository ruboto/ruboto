package THE_PACKAGE;

import org.ruboto.Script;
import org.ruboto.ScriptLoader;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS implements RubotoComponent {
THE_CONSTANTS

    private final ScriptInfo scriptInfo = new ScriptInfo(CONSTANTS_COUNT);

    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    /****************************************************************************************
     *
     *  Service Lifecycle: onCreate
     */

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
	public void onCreateSuper() {
	    super.onCreate();
	}

    @Override
    public void onCreate() {
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate();
            return;
        }
	    System.out.println("RubotoService.onCreate()");

        if (JRubyAdapter.setUpJRuby(this)) {
            // TODO(uwe):  Only needed for non-class-based definitions
            // Can be removed if we stop supporting non-class-based definitions
    	    JRubyAdapter.defineGlobalVariable("$context", this);
    	    JRubyAdapter.defineGlobalVariable("$service", this);
    	    // TODO end

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
