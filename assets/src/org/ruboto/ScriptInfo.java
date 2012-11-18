package org.ruboto;

public class ScriptInfo {
    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;

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
