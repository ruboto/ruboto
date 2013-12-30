package THE_PACKAGE;

import org.ruboto.Script;
import org.ruboto.ScriptLoader;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    /**
     * Called at the start of onCreate() to prepare the Activity.
     */
    private void preOnCreate() {
        System.out.println("RubotoService onCreate(): " + getClass().getName());
        getScriptInfo().setRubyClassName(getClass().getSimpleName());
    }

THE_METHODS

}
