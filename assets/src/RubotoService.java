package THE_PACKAGE;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.embed.ScriptingContainer;
import org.jruby.exceptions.RaiseException;
import org.ruboto.Script;
import java.io.IOException;
import android.app.ProgressDialog;

public abstract class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private ScriptingContainer __ruby__;
  private String scriptName;
  private String remoteVariable = "";
  public Object[] args;

THE_CONSTANTS
  private IRubyObject[] callbackProcs = new IRubyObject[CONSTANTS_COUNT];

  private ScriptingContainer getRuby() {
    if (__ruby__ == null) __ruby__ = Script.getRuby();

    if (__ruby__ == null) {
      Script.setUpJRuby(this);
      __ruby__ = Script.getRuby();
    }

    return __ruby__;
  }

  public void setCallbackProc(int id, IRubyObject obj) {
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

    getRuby();

    Script.defineGlobalVariable("$service", this);

    try {
      new Script(scriptName).execute();
    } catch(IOException e) {
      e.printStackTrace();
    }
  }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS
}	


