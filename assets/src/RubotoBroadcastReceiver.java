package THE_PACKAGE;

import java.io.IOException;

import org.jruby.embed.ScriptingContainer;
import org.jruby.runtime.builtin.IRubyObject;

public abstract class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private ScriptingContainer __ruby__;
  private String scriptName;
  private String remoteVariable = "";
  public Object[] args;

THE_CONSTANTS
  private IRubyObject[] callbackProcs = new IRubyObject[CONSTANTS_COUNT];

  private ScriptingContainer getRuby() {
    if (__ruby__ == null) {
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
  public void onReceive(android.content.Context arg0, android.content.Intent arg1) {
    args = new Object[2];
    args[0] = arg0;
    args[1] = arg1;

    getRuby();

    Script.defineGlobalVariable("$broadcast_receiver", this);
    Script.defineGlobalVariable("$broadcast_context", arg0);
    Script.defineGlobalVariable("$broadcast_intent", arg1);

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


