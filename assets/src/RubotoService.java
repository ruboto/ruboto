package THE_PACKAGE;

import org.ruboto.Script;
import java.io.IOException;
import android.app.ProgressDialog;

public abstract class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private String scriptName;
  private String remoteVariable = "";
  public Object[] args;

THE_CONSTANTS

  private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

  public void setCallbackProc(int id, Object obj) {
    callbackProcs[id] = obj;
  }
	
  public THE_RUBOTO_CLASS setRemoteVariable(String var) {
    remoteVariable = ((var == null) ? "" : (var + "."));
    return this;
  }

  public void setScriptName(String name){
    scriptName = name;
  }

  /****************************************************************************************
   * 
   *  Activity Lifecycle: onCreate
   */
	
  @Override
  public void onCreate() {
    args = new Object[0];

    super.onCreate();

    if (Script.setUpJRuby(this)) {
        Script.defineGlobalVariable("$service", this);
        try {
            new Script(scriptName).execute();
        } catch(IOException e) {
            e.printStackTrace();
        }
    } else {
      // FIXME(uwe):  What to do if the Ruboto Core plarform cannot be found?
    }
  }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}


