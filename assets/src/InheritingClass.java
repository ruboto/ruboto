// Generated Ruboto subclass with method base "THE_METHOD_BASE"

package THE_PACKAGE;

import org.ruboto.JRubyAdapter;
import org.ruboto.Log;
import org.ruboto.Script;
import org.ruboto.ScriptInfo;
import org.ruboto.ScriptLoader;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
THE_CONSTANTS

    private final ScriptInfo scriptInfo = new ScriptInfo(CONSTANTS_COUNT);
    {
		scriptInfo.setRubyClassName(getClass().getSimpleName());
		ScriptLoader.loadScript(this);
    }

THE_CONSTRUCTORS

    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
	public void onCreateSuper() {
	    // Do nothing
	}

THE_METHODS

}
