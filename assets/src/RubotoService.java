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
   *  Service Lifecycle: onCreate
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
                        // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                        if (isJRubyPreOneSeven() || isRubyOneEight()) {
                            JRubyAdapter.put("$java_instance", this);
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                        } else if (isJRubyOneSeven() && isRubyOneNine()) {
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.runRubyMethod(this, "singleton_class", Object.class));
                        } else {
                            throw new RuntimeException("Unknown JRuby/Ruby version: " + JRubyAdapter.get("JRUBY_VERSION") + "/" + JRubyAdapter.get("RUBY_VERSION"));
                        }
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
                    // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                    if (isJRubyPreOneSeven()) {
                        JRubyAdapter.put("$ruby_instance", this);
                        JRubyAdapter.runScriptlet("$ruby_instance.on_create");
                    } else if (isJRubyOneSeven()) {
                        JRubyAdapter.runRubyMethod(this, "on_create");
                    } else {
                        throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
                    }
                }
            } else {
                // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (isJRubyPreOneSeven()) {
            	    JRubyAdapter.runScriptlet("$service.initialize_ruboto");
            	    JRubyAdapter.runScriptlet("$service.on_create");
                } else if (isJRubyOneSeven()) {
            	    JRubyAdapter.runRubyMethod(this, "initialize_ruboto");
                    JRubyAdapter.runRubyMethod(this, "on_create", args[0]);
                } else {
                    throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
            	}
            }
        } catch(IOException e) {
            e.printStackTrace();
        }
    } else {
      // FIXME(uwe):  What to do if the Ruboto Core plarform cannot be found?
    }
  }

    private boolean isRubyOneEight() {
        return ((String)JRubyAdapter.get("RUBY_VERSION")).startsWith("1.8.");
    }

    private boolean isRubyOneNine() {
        return ((String)JRubyAdapter.get("RUBY_VERSION")).startsWith("1.9.");
    }

    private boolean isJRubyPreOneSeven() {
        return ((String)JRubyAdapter.get("JRUBY_VERSION")).equals("1.7.0.dev") || ((String)JRubyAdapter.get("JRUBY_VERSION")).equals("1.6.7");
    }

    private boolean isJRubyOneSeven() {
        return ((String)JRubyAdapter.get("JRUBY_VERSION")).startsWith("1.7.");
    }

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}


