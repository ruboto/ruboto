package THE_PACKAGE;

import java.io.IOException;

import org.ruboto.ScriptLoader;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
    private final ScriptInfo scriptInfo = new ScriptInfo();

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
                ScriptLoader.loadScript(this);
            }
        }
    }

    public void onReceive(android.content.Context context, android.content.Intent intent) {
        try {
            Log.d("onReceive: " + this + " " + ScriptLoader.isCalledFromJRuby());
            if (ScriptLoader.isCalledFromJRuby()) {
                return;
            }
            if (!scriptInfo.isLoaded()) {
                if (JRubyAdapter.setUpJRuby(context)) {
                    ScriptLoader.loadScript(this);
                } else {
                    // FIXME(uwe): What to do if the Ruboto Core platform is missing?
                }
            }

            // FIXME(uwe):  Simplify when we stop support for snake case aliasing interface callback methods.
            if ((Boolean)JRubyAdapter.runScriptlet(scriptInfo.getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :onReceive}")) {
                Log.d("onReceive: call method");
    	        JRubyAdapter.runRubyMethod(this, "onReceive", new Object[]{context, intent});
            } else if ((Boolean)JRubyAdapter.runScriptlet(scriptInfo.getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :on_receive}")) {
    	        JRubyAdapter.runRubyMethod(this, "on_receive", new Object[]{context, intent});
            }
            // EMXIF
        } catch(Exception e) {
            e.printStackTrace();
        }
    }

}
