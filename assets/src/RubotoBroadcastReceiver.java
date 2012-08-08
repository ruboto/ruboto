package THE_PACKAGE;

import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;
    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

    public void setCallbackProc(int id, Object obj) {
        // Error: no callbacks
        throw new RuntimeException("RubotoBroadcastReceiver does not accept callbacks");
    }
	
    public void setScriptName(String name){
        scriptName = name;
    }

    public THE_RUBOTO_CLASS() {
        this(null);
    }

    public THE_RUBOTO_CLASS(String name) {
        super();

        if (name != null) {
            setScriptName(name);
        
            if (JRubyAdapter.isInitialized()) {
                loadScript();
            }
        }
    }

    protected void loadScript() {
        rubyInstance = this;

        // TODO(uwe):  Only needed for non-class-based definitions
        // Can be removed if we stop supporting non-class-based definitions
    	JRubyAdapter.put("$broadcast_receiver", this);
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
                        if (JRubyAdapter.isJRubyPreOneSeven() || JRubyAdapter.isRubyOneEight()) {
                            JRubyAdapter.put("$java_instance", this);
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                        } else if (JRubyAdapter.isJRubyOneSeven() && JRubyAdapter.isRubyOneNine()) {
                            JRubyAdapter.put(rubyClassName, JRubyAdapter.runRubyMethod(this, "singleton_class"));
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

                            // TODO(uwe):  Why doesnt this work?
                            // JRubyAdapter.put(rubyClassName, JRubyAdapter.runScriptlet("Java::" + getClass().getName()));

                            // TODO(uwe):  Workaround...
                            JRubyAdapter.runScriptlet(rubyClassName + " = Java::" + getClass().getName());
                        }
                        // System.out.println("Set class: " + JRubyAdapter.get(rubyClassName));
                    }
                    JRubyAdapter.setScriptFilename(scriptName);
                    JRubyAdapter.runScriptlet(script);
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
            }
        } catch(IOException e) {
            throw new RuntimeException("IOException loading broadcast receiver script", e);
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        try {
            Log.d("onReceive: " + this);

            // FIXME(uwe):  Only needed for older broadcast receiver using callbacks
            // FIXME(uwe):  Remove if we stop suppporting callbacks (to avoid global variables).
            JRubyAdapter.put("$context", context);
            JRubyAdapter.put("$intent", intent);
            JRubyAdapter.put("$broadcast_receiver", this);
            // FIXME end

            // FIXME(uwe): Simplify when we stop supporting JRuby 1.6.x
            if (JRubyAdapter.isJRubyPreOneSeven()) {
                JRubyAdapter.runScriptlet("$broadcast_receiver.on_receive($context, $intent)");
            } else if (JRubyAdapter.isJRubyOneSeven()) {
        	    JRubyAdapter.runRubyMethod(this, "on_receive", new Object[]{context, intent});
            } else {
                throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
        	}
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

}
