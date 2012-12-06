package org.ruboto;

public class ScriptInfo {
    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;

    public void setFromIntent(android.context.Intent intent) {
      android.os.Bundle configBundle = intent.getBundleExtra("Ruboto Config");

      if (configBundle != null) {
        if (configBundle.containsKey("ClassName")) {
          setRubyClassName(configBundle.getString("ClassName"));
        }
        if (configBundle.containsKey("Script")) {
          setScriptName(configBundle.getString("Script"));
        }
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
