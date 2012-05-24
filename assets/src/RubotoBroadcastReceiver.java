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
        
            if (Script.isInitialized()) {
                loadScript();
            }
        }
    }

    protected void loadScript() {
        Script.put("$broadcast_receiver", this);
        if (scriptName != null) {
            try {
                new Script(scriptName).execute();
            } catch(IOException e) {
                throw new RuntimeException("IOException loading broadcast receiver script", e);
            }
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        Script.put("$context", context);
        Script.put("$broadcast_receiver", this);
        Script.put("$intent", intent);

        try {
            Script.execute("$broadcast_receiver.on_receive($context, $intent)");
        } catch(Exception e) {
            e.printStackTrace();
        }
    }
}	


