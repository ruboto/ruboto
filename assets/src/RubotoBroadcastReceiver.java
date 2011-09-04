package THE_PACKAGE;

import java.io.IOException;

public abstract class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private String scriptName;
    private String remoteVariable = "";

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

    public THE_RUBOTO_CLASS(String scriptName) {
        setScriptName(scriptName);
        if (Script.isInitialized()) {
            loadScript();
        }
    }

    protected void loadScript() {
        Script.put("$broadcast_receiver", this);
        try {
            new Script(scriptName).execute();
        } catch(IOException e) {
            throw new RuntimeException("IOException loading broadcast receiver script", e);
        }
    }

    /****************************************************************************************
     * 
     *  Generated Methods
     */

THE_METHODS

}	


