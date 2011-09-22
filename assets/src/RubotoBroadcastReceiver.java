package THE_PACKAGE;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private boolean initialized = false;

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

        if (name != null)
            setScriptName(name);
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        if (Script.setUpJRuby(context)) {
            Script.defineGlobalVariable("$context", context);
            Script.defineGlobalVariable("$broadcast_receiver", this);
            Script.defineGlobalVariable("$intent", intent);

            try {
                if (scriptName != null && !initialized) {
                    new Script(scriptName).execute();
                    initialized = true;
                } else {
                    Script.execute("$broadcast_receiver.on_receive($context, $intent)");
                }
            } catch(Exception e) {
                e.printStackTrace();
            }
        }
    }
}	


