package org.ruboto;

import android.app.ProgressDialog;
import android.content.Context;

import java.io.IOException;
import java.util.Map;

public class ScriptLoader {
   /**
    Return true if we are called from JRuby.
    */
    public static boolean isCalledFromJRuby() {
        StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
        int maxLookBack = Math.min(8, stackTraceElements.length);
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
                    boolean scriptContainsClass = script.matches("(?s).*class\\s+"
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
                            rubyClass = JRubyAdapter.runRubyMethod(component, "singleton_class");
                        }
                    }
                    if (rubyClass == null || !hasBackingJavaClass) {
                        Log.d("Loading script: " + component.getScriptInfo().getScriptName());
                        if (scriptContainsClass) {
                            Log.d("Script contains class definition");
                            if (rubyClass == null && hasBackingJavaClass) {
                                Log.d("Script has separate Java class");
                                rubyClass = JRubyAdapter.runScriptlet("Java::" + component.getClass().getName());
                            }
                            Log.d("Set class: " + rubyClass);
                            // FIXME(uwe): This should work
                            // JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), rubyClass);
                            // EMXIF

                            // FIXME(uwe): Workaround since setting the constant with `put` fails
                            JRubyAdapter.put("$" + component.getScriptInfo().getRubyClassName(), rubyClass);
                            JRubyAdapter.runScriptlet(component.getScriptInfo().getRubyClassName() + " = $" + component.getScriptInfo().getRubyClassName());
                            // EMXIF

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
            persistObjectProxy(component);
        } catch(IOException e){
            e.printStackTrace();
            if (component instanceof Context) {
                ProgressDialog.show((Context) component, "Script failed", "Something bad happened", true, true);
            }
        }
    }

    private static void persistObjectProxy(RubotoComponent component) {
        JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
        ((Map)JRubyAdapter.get("RUBOTO_JAVA_PROXIES")).put(component.getScriptInfo().getRubyInstance(), component.getScriptInfo().getRubyInstance());
    }

    public static void unloadScript(RubotoComponent component) {
        ((Map)JRubyAdapter.get("RUBOTO_JAVA_PROXIES")).remove(component.getScriptInfo().getRubyInstance());
    }

}
