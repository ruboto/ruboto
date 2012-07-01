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
    	JRubyAdapter.put("$broadcast_receiver", this);
        if (scriptName != null) {
            try {
                JRubyAdapter.exec(new Script(scriptName).getContents());
                String rubyClassName = Script.toCamelCase(scriptName);
                System.out.println("Looking for Ruby class: " + rubyClassName);
                Object rubyClass = JRubyAdapter.get(rubyClassName);
                if (rubyClass != null) {
                    System.out.println("Instanciating Ruby class: " + rubyClassName);
                    JRubyAdapter.put("$java_broadcast_receiver", this);
                    JRubyAdapter.exec("$ruby_broadcast_receiver = " + rubyClassName + ".new($java_broadcast_receiver)");
                    rubyInstance = JRubyAdapter.get("$ruby_broadcast_receiver");
                }
            } catch(IOException e) {
                throw new RuntimeException("IOException loading broadcast receiver script", e);
            }
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        try {
            System.out.println("onReceive: " + rubyInstance);
            JRubyAdapter.put("$context", context);
            JRubyAdapter.put("$broadcast_receiver", this);
            JRubyAdapter.put("$intent", intent);
            if (rubyInstance != null) {
            	JRubyAdapter.exec("$ruby_broadcast_receiver.on_receive($context, $intent)");
            } else {
            	JRubyAdapter.execute("$broadcast_receiver.on_receive($context, $intent)");
            }
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}	
