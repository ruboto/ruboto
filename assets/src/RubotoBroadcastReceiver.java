package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.ScriptLoader;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS implements RubotoComponent {
    private final ScriptInfo scriptInfo = new ScriptInfo(CONSTANTS_COUNT);

    public void setCallbackProc(int id, Object obj) {
        // Error: no callbacks
        throw new RuntimeException("RubotoBroadcastReceiver does not accept callbacks");
    }
	
    public ScriptInfo getScriptInfo() {
        return scriptInfo;
    }

    public THE_RUBOTO_CLASS() {
        this(null);
    }

    public THE_RUBOTO_CLASS(String name) {
        super();

        if (name != null) {
            scriptInfo.setScriptName(name);
        
            if (JRubyAdapter.isInitialized()) {
                // TODO(uwe):  Only needed for non-class-based definitions
                // Can be removed if we stop supporting non-class-based definitions
    	        JRubyAdapter.put("$broadcast_receiver", this);
    	        // TODO end

                ScriptLoader.loadScript(this);
            }
        }
    }

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
	public void onCreateSuper() {
	    // Do nothing
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
