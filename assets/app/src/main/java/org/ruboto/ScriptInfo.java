package org.ruboto;

public class ScriptInfo {
    public static final String CLASS_NAME_KEY = "RUBOTO_CLASS_NAME";
    public static final String SCRIPT_NAME_KEY = "RUBOTO_SCRIPT_NAME";
    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;

    public boolean isReadyToLoad() {
        return rubyClassName != null || scriptName != null;
    }

    public boolean isLoaded() {
        return rubyInstance != null;
    }

    public void setFromIntent(android.content.Intent intent) {

        // FIXME(uwe):  Deprecated as of Ruboto 0.13.0.  Remove in june 2014 (twelve months).
        android.os.Bundle configBundle = intent.getBundleExtra("Ruboto Config");
        if (configBundle != null) {
            if (configBundle.containsKey("ClassName")) {
                setRubyClassName(configBundle.getString("ClassName"));
            }
            if (configBundle.containsKey("Script")) {
                setScriptName(configBundle.getString("Script"));
            }
        }
        // EMXIF

        if (intent.hasExtra(CLASS_NAME_KEY)) {
            setRubyClassName(intent.getStringExtra(CLASS_NAME_KEY));
        }
        if (intent.hasExtra(SCRIPT_NAME_KEY)) {
            setScriptName(intent.getStringExtra(SCRIPT_NAME_KEY));
        }
    }

    public String getRubyClassName() {
        if (rubyClassName == null && scriptName != null) {
            return Script.toCamelCase(scriptName);
         }
        return rubyClassName;
    }

    public void setRubyClassName(String name) {
        rubyClassName = name;
    }

    public Object getRubyInstance() {
        return rubyInstance;
    }

    public void setRubyInstance(Object instance) {
        rubyInstance = instance;
    }

    public String getScriptName() {
        if (scriptName == null && rubyClassName != null) {
            return Script.toSnakeCase(rubyClassName) + ".rb";
        }
        return scriptName;
    }

    public void setScriptName(String name) {
        scriptName = name;
    }

}
