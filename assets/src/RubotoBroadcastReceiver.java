package THE_PACKAGE;

import java.io.IOException;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName = null;
    private Object rubyInstance;

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

        if (scriptName != null) {
            try {
                String rubyClassName = Script.toCamelCase(scriptName);
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = JRubyAdapter.get(rubyClassName);
                if (rubyClass == null) {
                    System.out.println("Loading script: " + scriptName);
                    JRubyAdapter.exec(new Script(scriptName).getContents());
                    rubyClass = JRubyAdapter.get(rubyClassName);
                }
                if (rubyClass != null) {
                    System.out.println("Instanciating Ruby class: " + rubyClassName);
                    rubyInstance = JRubyAdapter.callMethod(rubyClass, "new", this, Object.class);
                }
            } catch(IOException e) {
                throw new RuntimeException("IOException loading broadcast receiver script", e);
            }
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        try {
            System.out.println("onReceive: " + rubyInstance);
            if (rubyInstance != null) {
            	JRubyAdapter.callMethod(rubyInstance, "on_receive", new Object[]{context, intent});
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
