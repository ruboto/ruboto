package THE_PACKAGE;

import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName = null;

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
            // FIXME(uwe):  Change to use callMethod instead of runScriptlet
            String rubyClassName = Script.toCamelCase(scriptName);
            if ((Boolean)JRubyAdapter.runScriptlet("defined?(" + rubyClassName + ") == 'constant' && " + rubyClassName + ".instance_methods(false).any?{|m| m.to_sym == :on_receive}")) {
                Log.d("onReceive: Ruby method found");
                // FIXME(uwe):  Change to use callMethod instead of global variables
                JRubyAdapter.put("$context", context);
                JRubyAdapter.put("$intent", intent);
                JRubyAdapter.put("$ruby_instance", this);
                JRubyAdapter.runScriptlet("$ruby_instance.on_receive($context, $intent)");

            	// JRubyAdapter.callMethod(this, "on_receive", new Object[]{context, intent});
            } else {
                // TODO(uwe):  Only needed for non-class-based definitions
                // Can be removed if we stop supporting non-class-based definitions
                JRubyAdapter.put("$context", context);
                JRubyAdapter.put("$broadcast_receiver", this);
                JRubyAdapter.put("$intent", intent);
            	JRubyAdapter.execute("$broadcast_receiver.on_receive($context, $intent)");
            	// TODO end
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}	
