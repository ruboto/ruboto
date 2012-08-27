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

    static void loadScript(final RubotoComponent component, Object... args) {
        try {
            if (component.getScriptName() != null) {
                System.out.println("Looking for Ruby class: " + component.getRubyClassName());
                Object rubyClass = JRubyAdapter.get(component.getRubyClassName());
                System.out.println("Found: " + rubyClass);
                Script rubyScript = new Script(component.getScriptName());
                Object rubyInstance;
                if (rubyScript.exists()) {
                    rubyInstance = component;
                    final String script = rubyScript.getContents();
                    if (script.matches("(?s).*class " + component.getRubyClassName() + ".*")) {
                        if (!component.getRubyClassName().equals(component.getClass().getSimpleName())) {
                            System.out.println("Script defines methods on meta class");
                            // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                            if (JRubyAdapter.isJRubyPreOneSeven() || JRubyAdapter.isRubyOneEight()) {
                                JRubyAdapter.put("$java_instance", component);
                                JRubyAdapter.put(component.getRubyClassName(), JRubyAdapter.runScriptlet("class << $java_instance; self; end"));
                            } else if (JRubyAdapter.isJRubyOneSeven() && JRubyAdapter.isRubyOneNine()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                JRubyAdapter.put(component.getRubyClassName(), JRubyAdapter.runRubyMethod(component, "singleton_class"));
                            } else {
                                throw new RuntimeException("Unknown JRuby/Ruby version: " + JRubyAdapter.get("JRUBY_VERSION") + "/" + JRubyAdapter.get("RUBY_VERSION"));
                            }
                        }
                    }
                    if (rubyClass == null) {
                        System.out.println("Loading script: " + component.getScriptName());
                        if (script.matches("(?s).*class " + component.getRubyClassName() + ".*")) {
                            System.out.println("Script contains class definition");
                            if (component.getRubyClassName().equals(component.getClass().getSimpleName())) {
                                System.out.println("Script has separate Java class");
                                // FIXME(uwe): Simplify when we stop support for JRuby < 1.7.0
                                if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                    JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                                }
                                JRubyAdapter.put(component.getRubyClassName(), JRubyAdapter.runScriptlet("Java::" + component.getClass().getName()));
                            }
                            System.out.println("Set class: " + JRubyAdapter.get(component.getRubyClassName()));
                            Thread t = new Thread(new Runnable(){
                                public void run() {
                                    JRubyAdapter.setScriptFilename(component.getScriptName());
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
                            rubyClass = JRubyAdapter.get(component.getRubyClassName());
                        } else {
                            // FIXME(uwe): Only needed for initial block-based activity definition
                            System.out.println("Script contains block based activity definition");
                            if (!JRubyAdapter.isJRubyPreOneSeven()) {
                                JRubyAdapter.runScriptlet("Java::" + component.getClass().getName() + ".__persistent__ = true");
                            }
                            JRubyAdapter.runScriptlet("$activity.instance_variable_set '@ruboto_java_class', '" + component.getRubyClassName() + "'");
                            JRubyAdapter.runScriptlet("puts %Q{$activity: #$activity}");
                            JRubyAdapter.setScriptFilename(component.getScriptName());
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
                    System.out.println("Call on_create on: " + rubyInstance + ", " + JRubyAdapter.get("JRUBY_VERSION"));
                    // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                    if (JRubyAdapter.isJRubyPreOneSeven()) {
                        JRubyAdapter.put("$ruby_instance", rubyInstance);
                        JRubyAdapter.runScriptlet("$ruby_instance.on_create($bundle)");
                    } else if (JRubyAdapter.isJRubyOneSeven()) {
                        JRubyAdapter.runRubyMethod(rubyInstance, "on_create", (Object[]) args);
                    } else {
                        throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
                    }
                } else {
                    // FIXME(uwe): Remove when we stop supporting block based main activities.
                    component.onCreate((Object[]) args);
                }
                component.setRubyInstance(rubyInstance);
            } else { // if (configBundle != null) {
                // FIXME(uwe): Simplify when we stop support for RubotoCore 0.4.7
                if (JRubyAdapter.isJRubyPreOneSeven()) {
            	    JRubyAdapter.runScriptlet("$activity.initialize_ruboto");
            	    JRubyAdapter.runScriptlet("$activity.on_create($bundle)");
                } else if (JRubyAdapter.isJRubyOneSeven()) {
            	    JRubyAdapter.runRubyMethod(component, "initialize_ruboto");
                    JRubyAdapter.runRubyMethod(component, "on_create", (Object[]) args);
                } else {
                    throw new RuntimeException("Unknown JRuby version: " + JRubyAdapter.get("JRUBY_VERSION"));
            	}
            }
        } catch(IOException e){
            e.printStackTrace();
            if (component.getContext() != null) {
                ProgressDialog.show(component.getContext(), "Script failed", "Something bad happened", true, true);
            }
        }
    }

}
