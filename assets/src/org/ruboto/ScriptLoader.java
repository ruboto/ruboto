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
        int maxLookBack = Math.min(10, stackTraceElements.length);
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
                Script rubyScript = new Script(component.getScriptInfo().getScriptName());
                Object rubyInstance;
                if (rubyScript.exists()) {
                    rubyInstance = component;
                    final String script = rubyScript.getContents();
                    if (script.matches("(?s).*class " + component.getScriptInfo().getRubyClassName() + ".*")) {
                        if (!component.getScriptInfo().getRubyClassName().equals(component.getClass().getSimpleName())) {
                            System.out.println("Script defines methods on meta class");
                            // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                            if (JRubyAdapter.isJRubyPreOneSeven() || JRubyAdapter.isRubyOneEight()) {
                                JRubyAdapter.put("$java_instance", component);
                                JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                            } else if (JRubyAdapter.isJRubyOneSeven() && JRubyAdapter.isRubyOneNine()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), JRubyAdapter.runRubyMethod(component, "singleton_class"));
                            } else {
                                throw new RuntimeException("Unknown JRuby/Ruby version: " + JRubyAdapter.get("JRUBY_VERSION") + "/" + JRubyAdapter.get("RUBY_VERSION"));
                            }
                        }
                    }
                    if (rubyClass == null) {
                        System.out.println("Loading script: " + component.getScriptInfo().getScriptName());
                        if (script.matches("(?s).*class " + component.getScriptInfo().getRubyClassName() + ".*")) {
                            System.out.println("Script contains class definition");
                            if (component.getScriptInfo().getRubyClassName().equals(component.getClass().getSimpleName())) {
                                System.out.println("Script has separate Java class");
                                // FIXME(uwe): Simplify when we stop support for JRuby < 1.7.0
                                if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                    JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                }
                                JRubyAdapter.put(component.getScriptInfo().getRubyClassName(), JRubyAdapter.runScriptlet("Java::" + component.getClass().getName()));
                            }
                            System.out.println("Set class: " + JRubyAdapter.get(component.getScriptInfo().getRubyClassName()));
                            Thread t = new Thread(new Runnable(){
                                public void run() {
                                    JRubyAdapter.setScriptFilename(component.getScriptInfo().getScriptName());
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
                            rubyClass = JRubyAdapter.get(component.getScriptInfo().getRubyClassName());
                        } else {
                            // FIXME(uwe): Only needed for initial block-based activity definition
                            System.out.println("Script contains block based activity definition");
                            if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                            }
                            JRubyAdapter.runScriptlet("$activity.instance_variable_set '@ruboto_java_class', '" + component.getScriptInfo().getRubyClassName() + "'");
                            JRubyAdapter.runScriptlet("puts %Q{$activity: #$activity}");
                            JRubyAdapter.setScriptFilename(component.getScriptInfo().getScriptName());
                            JRubyAdapter.runScriptlet(script);
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
                } else {
                    // FIXME(uwe): Remove when we stop supporting block based main activities.
                    component.onCreateSuper();
                }
                component.getScriptInfo().setRubyInstance(rubyInstance);
            } else { // if (configBundle != null) {
                // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (JRubyAdapter.isJRubyPreOneSeven()) {
            	    JRubyAdapter.runScriptlet("$activity.initialize_ruboto");
                } else if (JRubyAdapter.isJRubyOneSeven()) {
            	    JRubyAdapter.runRubyMethod(component, "initialize_ruboto");
                } else {
                    throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
            	}
                if (component instanceof android.content.Context) {
                    callOnCreate(component, args);
                }
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
