package THE_PACKAGE;

import org.ruboto.Script;
import org.ruboto.ScriptLoader;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    /**
     * Called at the start of onCreate() to prepare the Activity.
     */
    private void preOnCreate() {
        if (!getClass().getSimpleName().equals("RubotoService")) {
          System.out.println("RubotoService onCreate(): " + getClass().getName());
          getScriptInfo().setRubyClassName(getClass().getSimpleName());
        }
    }

    private void preOnStartCommand(android.content.Intent intent) {
        if (getClass().getSimpleName().equals("RubotoService")) {
          System.out.println("RubotoService onStartCommand(): " + getClass().getName());
          scriptInfo.setFromIntent(intent);
        }
    }

    private void preOnBind(android.content.Intent intent) {
        if (getClass().getSimpleName().equals("RubotoService")) {
          System.out.println("RubotoService onBind(): " + getClass().getName());
          scriptInfo.setFromIntent(intent);
        }
    }

THE_METHODS

}
