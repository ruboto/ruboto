package org.ruboto;

import java.io.IOException;

import android.app.ProgressDialog;
import android.content.Context;
import android.os.Bundle;

public class ScriptLoader {
   /**
    Return true if we are called from JRuby.
    */
    public static boolean isCalledFromJRuby() {
        StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
        int maxLookBack = Math.min(9, stackTraceElements.length);
        for(int i = 0; i < maxLookBack ; i++){
            if (stackTraceElements[i].getClassName().startsWith("org.jruby.javasupport.JavaMethod")) {
                return true;
            }
        }
        return false;
    }

    public static void loadScript(final RubotoComponent component) {
        try {
            if (component.getScriptInfo().getScriptName() != null) {
                Log.d("Looking for Ruby class: " + component.getScriptInfo().getRubyClassName());
                Object rubyClass = JRubyAdapter.get(component.getScriptInfo().getRubyClassName());
                Log.d("Found: " + rubyClass);
                final Script rubyScript = new Script(component.getScriptInfo().getScriptName());
                Object rubyInstance;
                if (rubyScript.exists()) {
                    Log.d("Found script.");
                    rubyInstance = component;
                    final String script = rubyScript.getContents();
                    boolean scriptContainsClass = script.matches("(?s).*class "
                            + component.getScriptInfo().getRubyClassName() + ".*");
                    boolean hasBackingJavaClass = component.getScriptInfo().getRubyClassName()
                            .equals(component.getClass().getSimpleName());
                    if (scriptContainsClass) {
                        if (hasBackingJavaClass) {
                            Log.d("hasBackingJavaClass");
                            if (rubyClass != null && !rubyClass.toString().startsWith("Java::")) {
                                Log.d("Found Ruby class instead of Java class.  Reloading.");
                                rubyClass = null;
                            }
                        } else {
                            Log.d("Script defines methods on meta class");

                            // FIXME(uwe): Simplify when we stop support for Ruby 1.8 mode.
                            if (JRubyAdapter.isRubyOneEight()) {
                                JRubyAdapter.put("$java_instance", component);
                                rubyClass = JRubyAdapter.runScriptlet("class << $java_instance; self; end");
                            } else if (JRubyAdapter.isRubyOneNine()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                rubyClass = JRubyAdapter.runRubyMethod(component, "singleton_class");
                            } else {
                                throw new RuntimeException("Unknown Ruby version: " + JRubyAdapter.get("RUBY_VERSION"));
                            }
                            // EMXIF

                        }
                    }
                    if (rubyClass == null || !hasBackingJavaClass) {
                        Log.d("Loading script: " + component.getScriptInfo().getScriptName());
                        if (scriptContainsClass) {
                            Log.d("Script contains class definition");
                            if (rubyClass == null && hasBackingJavaClass) {
                                Log.d("Script has separate Java class");
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                rubyClass = JRubyAdapter.runScriptlet("Java::" + component.getClass().getName());
                            }
                            Log.d("Set class: " + rubyClass);
                            JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), rubyClass);
                            // FIXME(uwe):  Collect these threads in a ThreadGroup ?
                            Thread t = new Thread(null, new Runnable(){
                                public void run() {
                                    long loadStart = System.currentTimeMillis();
                                    JRubyAdapter.setScriptFilename(rubyScript.getAbsolutePath());
                                    JRubyAdapter.runScriptlet(script);
                                    Log.d("Script load took " + (System.currentTimeMillis() - loadStart) + "ms");
                                }
                            }, "ScriptLoader for " + rubyClass, 128 * 1024);
                            try {
                                t.start();
                                t.join();
                            } catch(InterruptedException ie) {
                                Thread.currentThread().interrupt();
                                throw new RuntimeException("Interrupted loading script.", ie);
                            }
                        } else {
                            throw new RuntimeException("Expected file "
                                    + component.getScriptInfo().getScriptName()
                                    + " to define class "
                                    + component.getScriptInfo().getRubyClassName());
                        }
                    }
                } else if (rubyClass != null) {
                    // We have a predefined Ruby class without corresponding Ruby source file.
                    Log.d("Create separate Ruby instance for class: " + rubyClass);
                    rubyInstance = JRubyAdapter.runRubyMethod(rubyClass, "new");
                    JRubyAdapter.runRubyMethod(rubyInstance, "instance_variable_set", "@ruboto_java_instance", component);
                } else {
                    // Neither script file nor predefined class
                    Log.e("Missing script and class.  Either script or predefined class must be present.");
                    throw new RuntimeException("Either script or predefined class must be present.");
                }
                component.getScriptInfo().setRubyInstance(rubyInstance);
            }
        } catch(IOException e){
            e.printStackTrace();
            if (component instanceof android.content.Context) {
                ProgressDialog.show((android.content.Context) component, "Script failed", "Something bad happened", true, true);
            }
        }
    }

    public static final void callOnCreate(final RubotoComponent component, Object... args) {
        if (component instanceof android.content.Context) {
            Log.d("Call onCreate on: " + component.getScriptInfo().getRubyInstance());
            // FIXME(uwe):  Simplify when we stop support for snake case aliasing interface callback methods.
            if ((Boolean)JRubyAdapter.runScriptlet(component.getScriptInfo().getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :onCreate}")) {
                JRubyAdapter.runRubyMethod(component.getScriptInfo().getRubyInstance(), "onCreate", args);
            } else if ((Boolean)JRubyAdapter.runScriptlet(component.getScriptInfo().getRubyClassName() + ".instance_methods(false).any?{|m| m.to_sym == :on_create}")) {
                JRubyAdapter.runRubyMethod(component.getScriptInfo().getRubyInstance(), "on_create", args);
            }
            // EMXIF
        }
    }

}
