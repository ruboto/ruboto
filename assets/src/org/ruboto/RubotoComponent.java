package org.ruboto;

public interface RubotoComponent {
    ScriptInfo getScriptInfo();

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
    void onCreateSuper();
}
