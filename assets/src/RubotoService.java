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
		  // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
      if (JRubyAdapter.isJRubyPreOneSeven()) {
        JRubyAdapter.put("$arg_intent", intent);
        JRubyAdapter.put("$arg_flags", flags);
        JRubyAdapter.put("$arg_startId", startId);
        JRubyAdapter.put("$ruby_instance", scriptInfo.getRubyInstance());
        return (Integer) ((Number)JRubyAdapter.runScriptlet("$ruby_instance.on_start_command($arg_intent, $arg_flags, $arg_startId)")).intValue();
      } else {
        if (JRubyAdapter.isJRubyOneSeven()) {
          return (Integer) JRubyAdapter.runRubyMethod(Integer.class, scriptInfo.getRubyInstance(), "on_start_command", new Object[]{intent, flags, startId});
        } else {
          throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
        }
      }
    } else {
      if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :onStartCommand}")) {
        // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
        if (JRubyAdapter.isJRubyPreOneSeven()) {
          JRubyAdapter.put("$arg_intent", intent);
          JRubyAdapter.put("$arg_flags", flags);
          JRubyAdapter.put("$arg_startId", startId);
          JRubyAdapter.put("$ruby_instance", scriptInfo.getRubyInstance());
          return (Integer) ((Number)JRubyAdapter.runScriptlet("$ruby_instance.onStartCommand($arg_intent, $arg_flags, $arg_startId)")).intValue();
        } else {
          if (JRubyAdapter.isJRubyOneSeven()) {
            return (Integer) JRubyAdapter.runRubyMethod(Integer.class, scriptInfo.getRubyInstance(), "onStartCommand", new Object[]{intent, flags, startId});
          } else {
            throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
          }
        }
      } else {
        return super.onStartCommand(intent, flags, startId);
      }
    }
  }

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
      // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
      if (JRubyAdapter.isJRubyPreOneSeven()) {
        JRubyAdapter.put("$arg_intent", intent);
        JRubyAdapter.put("$ruby_instance", scriptInfo.getRubyInstance());
        return (android.os.IBinder) JRubyAdapter.runScriptlet("$ruby_instance.on_bind($arg_intent)");
      } else {
        if (JRubyAdapter.isJRubyOneSeven()) {
          return (android.os.IBinder) JRubyAdapter.runRubyMethod(android.os.IBinder.class, scriptInfo.getRubyInstance(), "on_bind", intent);
        } else {
          throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
        }
      }
    } else {
      if ((Boolean)JRubyAdapter.runScriptlet(rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :onBind}")) {
        // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
        if (JRubyAdapter.isJRubyPreOneSeven()) {
          JRubyAdapter.put("$arg_intent", intent);
          JRubyAdapter.put("$ruby_instance", scriptInfo.getRubyInstance());
          return (android.os.IBinder) JRubyAdapter.runScriptlet("$ruby_instance.onBind($arg_intent)");
        } else {
          if (JRubyAdapter.isJRubyOneSeven()) {
            return (android.os.IBinder) JRubyAdapter.runRubyMethod(android.os.IBinder.class, scriptInfo.getRubyInstance(), "onBind", intent);
          } else {
            throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
          }
        }
      } else {
        return null;
      }
    }
  }


  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
