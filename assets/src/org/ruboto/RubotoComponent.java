package org.ruboto;

interface RubotoComponent {
    android.content.Context getContext();
    String getRubyClassName();
    String getScriptName();
    void setRubyInstance(Object instance);

    // FIXME(uwe):  Only used for block based primary activities.  Remove if we remove support for such.
    void onCreate(Object... args);
}
