package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.Script;

import android.app.ProgressDialog;
import android.os.Bundle;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
THE_CONSTANTS

    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;
    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];
    private String remoteVariable = null;
    private Bundle[] args;
    private Bundle configBundle = null;

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

    public void setRubyClassName(String name) {
        rubyClassName = name;
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
        System.out.println("RubotoActivity onCreate(): " + getClass().getName());
        if (ScriptLoader.isCalledFromJRuby()) {
            super.onCreate(bundle);
            return;
        }
        args = new Bundle[1];
        args[0] = bundle;

        configBundle = getIntent().getBundleExtra("RubotoActivity Config");

        if (configBundle != null) {
            if (configBundle.containsKey("Theme")) {
                setTheme(configBundle.getInt("Theme"));
            }
            if (configBundle.containsKey("ClassName")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setRubyClassName(configBundle.getString("ClassName"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set class name.");
                }
            }
            if (configBundle.containsKey("Script")) {
                if (this.getClass().getName() == RubotoActivity.class.getName()) {
                    setScriptName(configBundle.getString("Script"));
                } else {
                    throw new IllegalArgumentException("Only local Intents may set script name.");
                }
            }
        }

        if (rubyClassName == null && scriptName != null) {
            rubyClassName = Script.toCamelCase(scriptName);
        }
        if (scriptName == null && rubyClassName != null) {
            setScriptName(Script.toSnakeCase(rubyClassName) + ".rb");
        }

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
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = JRubyAdapter.get(rubyClassName);
                System.out.println("Found: " + rubyClass);
                Script rubyScript = new Script(scriptName);
                if (rubyScript.exists()) {
                    rubyInstance = this;
                    final String script = rubyScript.getContents();
                    if (script.matches("(?s).*class " + rubyClassName + ".*")) {
                        if (!rubyClassName.equals(getClass().getSimpleName())) {
                            System.out.println("Script defines methods on meta class");
                            // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                            if (JRubyAdapter.isJRubyPreOneSeven() || JRubyAdapter.isRubyOneEight()) {
                                JRubyAdapter.put("$java_instance", this);
                                JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                            } else if (JRubyAdapter.isJRubyOneSeven() && JRubyAdapter.isRubyOneNine()) {
                                JRubyAdapter.runScriptlet("Java::" + getClass().getName() + ".__persistent__ = true");
                                JRubyAdapter.put(rubyClassName, JRubyAdapter.runRubyMethod(this, "singleton_class"));
                            } else {
                                throw new RuntimeException("Unknown JRuby/Ruby version: " + JRubyAdapter.get("JRUBY_VERSION") + "/" + JRubyAdapter.get("RUBY_VERSION"));
                            }
                        }
                    }
                    if (rubyClass == null) {
                        System.out.println("Loading script: " + scriptName);
                        if (script.matches("(?s).*class " + rubyClassName + ".*")) {
                            System.out.println("Script contains class definition");
                            if (rubyClassName.equals(getClass().getSimpleName())) {
                                System.out.println("Script has separate Java class");
                                // FIXME(uwe): Simplify when we stop support for JRuby < 1.7.0
                                if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                    JRubyAdapter.runScriptlet("Java::" + getClass().getName() + ".__persistent__ = true");
                                }
                                JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("Java::" + getClass().getName()));
                            }
                            System.out.println("Set class: " + JRubyAdapter.get(rubyClassName));
                            Thread t = new Thread(new Runnable(){
                                public void run() {
                                    JRubyAdapter.setScriptFilename(scriptName);
                                    JRubyAdapter.runScriptlet(script);
                                }
                            });
                            try {
                                t.start();
                                t.join();
                            } catch(InterruptedException ie) {
                                Thread.currentThread().interrupt();
                                throw new RuntimeException("Interrupted loading script.", ie);
                            }
                            rubyClass = JRubyAdapter.get(rubyClassName);
                        } else {
                            // FIXME(uwe): Only needed for initial block-based activity definition
                            System.out.println("Script contains block based activity definition");
                            if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                JRubyAdapter.runScriptlet("Java::" + getClass().getName() + ".__persistent__ = true");
                            }
                            JRubyAdapter.runScriptlet("$activity.instance_variable_set '@ruboto_java_class', '" + rubyClassName + "'");
                            JRubyAdapter.runScriptlet("puts %Q{$activity: #$activity}");
                            JRubyAdapter.setScriptFilename(scriptName);
                            JRubyAdapter.runScriptlet(script);
                        }
                    }
                } else if (rubyClass != null) {
                    // We have a predefined Ruby class without corresponding Ruby source file.
                    System.out.println("Create separate Ruby instance for class: " + rubyClass);
                    rubyInstance = JRubyAdapter.runRubyMethod(rubyClass, "new");
                    JRubyAdapter.runRubyMethod(rubyInstance, "instance_variable_set", "@ruboto_java_instance", this);
                } else {
                    // Neither script file nor predefined class
                    throw new RuntimeException("Either script or predefined class must be present.");
                }
                if (rubyClass != null) {
                    System.out.println("Call on_create on: " + rubyInstance + ", " + JRubyAdapter.get("JRUBY_VERSION"));
                    // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                    if (JRubyAdapter.isJRubyPreOneSeven()) {
                        JRubyAdapter.put("$ruby_instance", rubyInstance);
                        JRubyAdapter.runScriptlet("$ruby_instance.on_create($bundle)");
                    } else if (JRubyAdapter.isJRubyOneSeven()) {
                        JRubyAdapter.runRubyMethod(rubyInstance, "on_create", args[0]);
                    } else {
                        throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
                    }
                } else {
                    // FIXME(uwe): Remove when we stop supporting block based main activities.
                    super.onCreate(args[0]);
                }
            } else if (configBundle != null) {
                // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (JRubyAdapter.isJRubyPreOneSeven()) {
            	    JRubyAdapter.runScriptlet("$activity.initialize_ruboto");
            	    JRubyAdapter.runScriptlet("$activity.on_create($bundle)");
                } else if (JRubyAdapter.isJRubyOneSeven()) {
            	    JRubyAdapter.runRubyMethod(this, "initialize_ruboto");
                    JRubyAdapter.runRubyMethod(this, "on_create", args[0]);
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

  /****************************************************************************************
   * 
   *  Generated Methods
   */

THE_METHODS

}
