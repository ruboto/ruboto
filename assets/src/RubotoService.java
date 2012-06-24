package THE_PACKAGE;

import org.ruboto.Script;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private String scriptName;
  public Object[] args;
  private Object rubyInstance;

THE_CONSTANTS

  private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

  public void setCallbackProc(int id, Object obj) {
    callbackProcs[id] = obj;
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
	System.out.println("RubotoService.onCreate()");
    args = new Object[0];

    super.onCreate();

    if (Script.setUpJRuby(this)) {
        Script.defineGlobalVariable("$context", this);
        Script.defineGlobalVariable("$service", this);

        try {
            if (scriptName != null) {
                System.out.println("Loading service script: " + scriptName);
                new Script(scriptName).execute();
                String rubyClassName = Script.toCamelCase(scriptName);
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = Script.get(rubyClassName);
                if (rubyClass != null) {
                    System.out.println("Instanciating Ruby class: " + rubyClassName);
                    Script.put("$java_service", this);
                    Script.exec("$ruby_service = " + rubyClassName + ".new($java_service)");
                    rubyInstance = Script.get("$ruby_service");
                    Script.exec("$ruby_service.on_create");
                }
            } else {
                Script.execute("$service.initialize_ruboto");
                Script.execute("$service.on_create");
            }
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


