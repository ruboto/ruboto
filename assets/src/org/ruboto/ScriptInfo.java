package org.ruboto;

public class ScriptInfo {
    private String rubyClassName;
    private String scriptName;
    private Object rubyInstance;

    // FIXME(uwe):  Only used for legacy handle_xxx callbacks.  Remove when we stop supporting these.
    private final Object[] callbackProcs;

    public ScriptInfo(int callbackSize) {
        callbackProcs = new Object[callbackSize];
    }

    public Object[] getCallbackProcs() {
        return callbackProcs;
    }

    public void setCallbackProc(int id, Object obj) {
        callbackProcs[id] = obj;
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
