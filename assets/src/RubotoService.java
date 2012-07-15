package THE_PACKAGE;

import org.ruboto.Script;
import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private String scriptName;
  public Object[] args;

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

    if (JRubyAdapter.setUpJRuby(this)) {
        // TODO(uwe):  Only needed for non-class-based definitions
        // Can be removed if we stop supporting non-class-based definitions
    	JRubyAdapter.defineGlobalVariable("$context", this);
    	JRubyAdapter.defineGlobalVariable("$service", this);
    	// TODO end

        try {
            if (scriptName != null) {
                String rubyClassName = Script.toCamelCase(scriptName);
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = null;
                String script = new Script(scriptName).getContents();
                if (script.matches("(?s).*class " + rubyClassName + ".*")) {
                    if (!rubyClassName.equals(getClass().getSimpleName())) {
                        System.out.println("Script defines methods on meta class");
                        JRubyAdapter.put("$java_instance", this);
                        JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                    }
                } else {
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
                if (rubyClass == null) {
                    System.out.println("Loading script: " + scriptName);
                    if (script.matches("(?s).*class " + rubyClassName + ".*")) {
                        System.out.println("Script contains class definition");
                        if (rubyClassName.equals(getClass().getSimpleName())) {
                            System.out.println("Script has separate Java class");
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("Java::" + getClass().getName()));
                        }
                        // System.out.println("Set class: " + JRubyAdapter.get(rubyClassName));
                    }
                    JRubyAdapter.setScriptFilename(scriptName);
                    JRubyAdapter.runScriptlet(script);
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
                if (rubyClass != null) {
                    System.out.println("Call on_create on: " + this);
                    JRubyAdapter.put("$ruby_instance", this);
                    JRubyAdapter.runScriptlet("$ruby_instance.on_create");
                }
            } else {
            	JRubyAdapter.execute("$service.initialize_ruboto");
            	JRubyAdapter.execute("$service.on_create");
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


