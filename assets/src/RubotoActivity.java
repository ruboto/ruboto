package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private String remoteVariable = null;
    private Object[] args;
    private Bundle configBundle = null;

THE_CONSTANTS

    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

    public void setCallbackProc(int id, Object obj) {
        callbackProcs[id] = obj;
    }
	
    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = var;
        return this;
    }

    public String getRemoteVariableCall(String call) {
        return (remoteVariable == null ? "" : (remoteVariable + ".")) + call;
    }

    public void setScriptName(String name) {
        scriptName = name;
    }

    /****************************************************************************************
     *
     *  Activity Lifecycle: onCreate
     */
	
    @Override
    public void onCreate(Bundle bundle) {
        args = new Object[1];
        args[0] = bundle;

        configBundle = getIntent().getBundleExtra("RubotoActivity Config");

        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
            if (configBundle.containsKey("Script")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setScriptName(configBundle.getString("Script"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set script name.");
                }
            }
        }

        super.onCreate(bundle);

        if (JRubyAdapter.isInitialized()) {
            prepareJRuby();
    	    loadScript();
        }
    }

    // TODO(uwe):  Only needed for non-class-based definitions
    // Can be removed if we stop supporting non-class-based definitions
    // This causes JRuby to initialize and takes a while.
    protected void prepareJRuby() {
    	JRubyAdapter.put("$context", this);
    	JRubyAdapter.put("$activity", this);
    	JRubyAdapter.put("$bundle", args[0]);
    }
    // TODO end

    protected void loadScript() {
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
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.callMethod(this, "singleton_class", Object.class));
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
                        // FIXME(uwe):  Why does this fail when running the navigation test with older JRuby?
                        if (!isJRubyPreOneSeven()) {
                          System.out.println("Set class: " + JRubyAdapter.get(rubyClassName));
                        }
                    }
                    JRubyAdapter.setScriptFilename(scriptName);
                    JRubyAdapter.runScriptlet(script);
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
                if (rubyClass != null) {
                    System.out.println("Call on_create on: " + this + ", " + JRubyAdapter.get("JRUBY_VERSION"));
                    // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                    if (isJRubyPreOneSeven()) {
                        JRubyAdapter.put("$ruby_instance", this);
                        JRubyAdapter.runScriptlet("$ruby_instance.on_create($bundle)");
                    } else if (isJRubyOneSeven()) {
                        JRubyAdapter.callMethod(this, "on_create", args[0]);
                    } else {
                        throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
                    }
                }
            } else if (configBundle != null) {
                // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (isJRubyPreOneSeven()) {
            	    JRubyAdapter.execute("$activity.initialize_ruboto");
                } else if (isJRubyOneSeven()) {
            	    JRubyAdapter.callMethod(this, "initialize_ruboto");
                } else {
                    throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
            	}
            	// FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (isJRubyPreOneSeven()) {
            	    JRubyAdapter.execute("$activity.on_create($bundle)");
                } else if (isJRubyOneSeven()) {
                    JRubyAdapter.callMethod(this, "on_create", args[0]);
                } else {
                    throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
            	}
            }
        } catch(IOException e){
            e.printStackTrace();
            ProgressDialog.show(this, "Script failed", "Something bad happened", true, true);
        }
    }

    public boolean rubotoAttachable() {
      return true;
    }

    private boolean isRubyOneEight() {
        return ((String)JRubyAdapter.get("RUBY_VERSION")).startsWith("1.8.");
    }

    private boolean isRubyOneNine() {
        return ((String)JRubyAdapter.get("RUBY_VERSION")).startsWith("1.9.");
    }

    private boolean isJRubyPreOneSeven() {
        return true; // ((String)JRubyAdapter.get("JRUBY_VERSION")).equals("1.7.0.dev") || ((String)JRubyAdapter.get("JRUBY_VERSION")).equals("1.6.7");
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
