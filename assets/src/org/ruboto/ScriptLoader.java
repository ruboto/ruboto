package org.ruboto;

import java.io.IOException;

import android.app.ProgressDialog;
import android.content.Context;

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

    public static void loadScript(final RubotoComponent component, Object... args) {
        try {
            if (component.getScriptInfo().getScriptName() != null) {
                System.out.println("Looking for Ruby class: " + component.getScriptInfo().getRubyClassName());
                Object rubyClass = JRubyAdapter.get(component.getScriptInfo().getRubyClassName());
                System.out.println("Found: " + rubyClass);
                final Script rubyScript = new Script(component.getScriptInfo().getScriptName());
                Object rubyInstance;
                if (rubyScript.exists()) {
                    rubyInstance = component;
                    final String script = rubyScript.getContents();
                    boolean scriptContainsClass = script.matches("(?s).*class "
                            + component.getScriptInfo().getRubyClassName() + ".*");
                    boolean hasBackingJavaClass = component.getScriptInfo().getRubyClassName()
                            .equals(component.getClass().getSimpleName());
                    if (scriptContainsClass) {
                        if (hasBackingJavaClass) {
                            if (rubyClass != null && !rubyClass.toString().startsWith("Java::")) {
                                System.out.println("Found Ruby class instead of Java class.  Reloading.");
                                rubyClass = null;
                            }
                        } else {
                            System.out.println("Script defines methods on meta class");

                            // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                            if (JRubyAdapter.isJRubyPreOneSeven() || JRubyAdapter.isRubyOneEight()) {
                                JRubyAdapter.put("$java_instance", component);
                                rubyClass = JRubyAdapter.runScriptlet("class << $java_instance; self; end");
                            } else if (JRubyAdapter.isJRubyOneSeven() && JRubyAdapter.isRubyOneNine()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                rubyClass = JRubyAdapter.runRubyMethod(component, "singleton_class");
                            } else {
                                throw new RuntimeException("Unknown JRuby/Ruby version: " + JRubyAdapter.get("JRUBY_VERSION") + "/" + JRubyAdapter.get("RUBY_VERSION"));
                            }
                            // EMXIF

                        }
                    }
                    if (rubyClass == null || !hasBackingJavaClass) {
                        System.out.println("Loading script: " + component.getScriptInfo().getScriptName());
                        if (scriptContainsClass) {
                            System.out.println("Script contains class definition");
                            if (rubyClass == null && hasBackingJavaClass) {
                                System.out.println("Script has separate Java class");

                                // FIXME(uwe): Simplify when we stop support for JRuby < 1.7.0
                                if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                    JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                }
                                // EMXIF

                                rubyClass = JRubyAdapter.runScriptlet("Java::" + component.getClass().getName());
                            }
                            System.out.println("Set class: " + rubyClass);
                            JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), rubyClass);
                            Thread t = new Thread(new Runnable(){
                                public void run() {
                                    JRubyAdapter.setScriptFilename(rubyScript.getAbsolutePath());
                                    JRubyAdapter.runScriptlet(script);
                                }
                            });
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
                    System.out.println("Create separate Ruby instance for class: " + rubyClass);
                    rubyInstance = JRubyAdapter.runRubyMethod(rubyClass, "new");
                    JRubyAdapter.runRubyMethod(rubyInstance, "instance_variable_set", "@ruboto_java_instance", component);
                } else {
                    // Neither script file nor predefined class
                    throw new RuntimeException("Either script or predefined class must be present.");
                }
                if (rubyClass != null) {
                    if (component instanceof android.content.Context) {
                        callOnCreate(rubyInstance, args);
                    }
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

    private static final void callOnCreate(Object rubyInstance, Object[] args) {
        System.out.println("Call on_create on: " + rubyInstance + ", " + JRubyAdapter.get("JRUBY_VERSION"));
        // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
        if (JRubyAdapter.isJRubyPreOneSeven()) {
            if (args.length > 0) {
                JRubyAdapter.put("$bundle", args[0]);
            }
            JRubyAdapter.put("$ruby_instance", rubyInstance);
            JRubyAdapter.runScriptlet("$ruby_instance.on_create(" + (args.length > 0 ? "$bundle" : "") + ")");
        } else if (JRubyAdapter.isJRubyOneSeven()) {
            JRubyAdapter.runRubyMethod(rubyInstance, "on_create", (Object[]) args);
        } else {
            throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
        }
    }

}
