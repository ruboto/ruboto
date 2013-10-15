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
      System.out.println("RubotoService onCreate(): " + getClass().getName());

      if (ScriptLoader.isCalledFromJRuby()) {
        super.onCreate();
        return;
      }

      if (JRubyAdapter.isInitialized() && scriptInfo.isReadyToLoad()) {
  	    ScriptLoader.loadScript(this);
      } else {
        super.onCreate();
      }
    }

  // FIXME(uwe):  Revert to generate these methods.
  @Override
  public int onStartCommand(android.content.Intent intent, int flags, int startId) {
	  if (ScriptLoader.isCalledFromJRuby()) return super.onStartCommand(intent, flags, startId);

    if (!JRubyAdapter.isInitialized()) {
      Log.i("Method called before JRuby runtime was initialized: RubotoService#onStartCommand");
      return super.onStartCommand(intent, flags, startId);
    }
	
    if (JRubyAdapter.isInitialized() && !scriptInfo.isLoaded()) {
      scriptInfo.setFromIntent(intent);
 	    ScriptLoader.loadScript(this);
    }
	  
	  String rubyClassName = scriptInfo.getRubyClassName();
	  if (rubyClassName == null) return super.onStartCommand(intent, flags, startId);
	  if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :on_start_command}")) {
        return (Integer) JRubyAdapter.runRubyMethod(Integer.class, scriptInfo.getRubyInstance(), "on_start_command", new Object[]{intent, flags, startId});
      } else {
      if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :onStartCommand}")) {
        return (Integer) JRubyAdapter.runRubyMethod(Integer.class, scriptInfo.getRubyInstance(), "onStartCommand", new Object[]{intent, flags, startId});
      } else {
        return super.onStartCommand(intent, flags, startId);
      }
    }
  }

  // FIXME(uwe):  Revert to generate these methods.
  @Override
  public android.os.IBinder onBind(android.content.Intent intent) {
    if (ScriptLoader.isCalledFromJRuby()) return null;
    if (!JRubyAdapter.isInitialized()) {
      Log.i("Method called before JRuby runtime was initialized: RubotoService#onBind");
      return null;
    }

    if (JRubyAdapter.isInitialized() && !scriptInfo.isLoaded()) {
      scriptInfo.setFromIntent(intent);
      ScriptLoader.loadScript(this);
    }
      
    String rubyClassName = scriptInfo.getRubyClassName();
    if (rubyClassName == null) return null;
    if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :on_bind}")) {
      return (android.os.IBinder) JRubyAdapter.runRubyMethod(android.os.IBinder.class, scriptInfo.getRubyInstance(), "on_bind", intent);
    } else {
      if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :onBind}")) {
        return (android.os.IBinder) JRubyAdapter.runRubyMethod(android.os.IBinder.class, scriptInfo.getRubyInstance(), "onBind", intent);
      } else {
        return null;
      }
    }
  }

    public void onDestroy() {
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onDestroy();
            return;
        }
        if (!JRubyAdapter.isInitialized()) {
            Log.i("Method called before JRuby runtime was initialized: RubotoActivity#onDestroy");
            super.onDestroy();
            return;
        }
        String rubyClassName = scriptInfo.getRubyClassName();
        if (rubyClassName == null) {
            super.onDestroy();
            return;
        }
        ScriptLoader.callOnDestroy(this);
    }


  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
