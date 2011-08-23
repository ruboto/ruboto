package THE_PACKAGE;

import java.io.IOException;

public abstract class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private String remoteVariable = "";
    public Object[] args;

THE_CONSTANTS

    private Object[] callbackProcs = new Object[CONSTANTS_COUNT];

    public void setCallbackProc(int id, Object obj) {
        callbackProcs[id] = obj;
    }
	
    public THE_RUBOTO_CLASS setRemoteVariable(String var) {
        remoteVariable = ((var == null) ? "" : (var + "."));
        return this;
    }

    public void setScriptName(String name){
        scriptName = name;
    }

    /****************************************************************************************
     * 
     *  Activity Lifecycle: onCreate
     */
	
    @Override
    public void onReceive(android.content.Context context, android.content.Intent intent) {
        args = new Object[2];
        args[0] = context;
        args[1] = intent;

        if (Script.setUpJRuby(context)) {
            Script.defineGlobalVariable("$broadcast_receiver", this);
            Script.defineGlobalVariable("$broadcast_context", context);
            Script.defineGlobalVariable("$broadcast_intent", intent);
            try {
                new Script(scriptName).execute();
            } catch(IOException e) {
                e.printStackTrace();
            }
        } else {
        	// FIXME(uwe): What to do if the Ruboto Core platform is missing?
        }
    }

    /****************************************************************************************
     * 
     *  Generated Methods
     */

THE_METHODS

}	


