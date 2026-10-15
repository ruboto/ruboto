package org.ruboto;

import android.app.ProgressDialog;
import android.content.Context;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class ScriptLoader {
    private static final Map<String, Boolean> methodCache = new ConcurrentHashMap<String, Boolean>();

   /**
    Return true if the Ruby class defines the given method.

    The generated component classes ask this before forwarding any Android
    callback.  Answering it means evaluating Ruby, and callbacks such as
    onUserInteraction fire once per input event, so the uncached version put a
    full parse of the predicate on the UI thread for every touch and every
    rotary tick.  On a watch that is enough to miss the input dispatcher's 5
    second deadline and be killed.

    The answer only changes when a script is evaluated, so it is cached until
    then; see clearMethodCache().
    */
    public static boolean hasRubyMethod(String rubyClassName, String methodName, boolean includeInherited) {
        final String key = rubyClassName + (includeInherited ? "#all#" : "#own#") + methodName;
        Boolean cached = methodCache.get(key);
        if (cached != null) {
            return cached;
        }
        Boolean defined = (Boolean) JRubyAdapter.runScriptlet(rubyClassName
                + ".instance_methods(" + includeInherited + ").any?{|m| m.to_sym == :" + methodName + "}");
        methodCache.put(key, defined);
        return defined;
    }

   /**
    Drop the cached method lookups.  Called whenever a script is evaluated,
    since that is the only thing that can change the answers.
    */
    public static void clearMethodCache() {
        methodCache.clear();
    }

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

   /**
    Define the Ruby class backing the given Activity ahead of time.

    Called from SplashActivity while the splash is up, so the script is evaluated
    there instead of in the Activity's onCreate.  loadScript() joins the script
    thread on whatever thread called it; when that is the UI thread, evaluating a
    script of any size starves the window focus handoff of its 5 second deadline
    and the app is killed with an ANR before it can draw.  Once the class is
    defined here, loadScript() finds it and returns without evaluating anything.

    Failures are logged and swallowed: loadScript() still runs afterwards and
    remains the authority on reporting a broken script.
    */
    public static void preloadScript(String javaClassName) {
        try {
            final Class<?> javaClass = Class.forName(javaClassName);
            final String rubyClassName = javaClass.getSimpleName();
            if (JRubyAdapter.get(rubyClassName) != null) {
                Log.d("Ruby class already defined: " + rubyClassName);
                return;
            }
            final Script rubyScript = new Script(Script.toSnakeCase(rubyClassName) + ".rb");
            if (!rubyScript.exists()) {
                Log.d("No script to preload for: " + rubyClassName);
                return;
            }
            final String script = rubyScript.getContents();
            if (!script.matches("(?s).*class\\s+" + rubyClassName + ".*")) {
                Log.d("Script does not define " + rubyClassName + ", leaving it to loadScript");
                return;
            }
            Log.d("Preloading script: " + rubyScript.getName());

            // Same handshake loadScript() performs, so it recognises the class as
            // the Java proxy and skips its own load.
            Object rubyClass = JRubyAdapter.runScriptlet("Java::" + javaClassName);
            JRubyAdapter.put("$" + rubyClassName, rubyClass);
            JRubyAdapter.runScriptlet(rubyClassName + " = $" + rubyClassName);

            // Evaluated on its own thread to keep the stack size loadScript uses.
            // join() does not rethrow what the child threw, so the failure is
            // handed back deliberately; without this a script that raises while
            // being evaluated would reach Android's default handler and kill the
            // process from under the splash.
            final Throwable[] failure = new Throwable[1];
            Thread t = new Thread(null, new Runnable() {
                public void run() {
                    long loadStart = System.currentTimeMillis();
                    try {
                        JRubyAdapter.setScriptFilename(rubyScript.getAbsolutePath());
                        JRubyAdapter.runScriptlet(script);
                        Log.d("Preload took " + (System.currentTimeMillis() - loadStart) + "ms");
                    } catch (Throwable e) {
                        failure[0] = e;
                    }
                }
            }, "ScriptLoader preload for " + rubyClassName, 128 * 1024);
            t.start();
            t.join();
            if (failure[0] != null) {
                // Leave the reporting to loadScript, which knows the component.
                Log.e("Preloading " + rubyClassName + " failed: " + failure[0]);
                return;
            }
            clearMethodCache();
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            Log.e("Interrupted preloading script: " + ie);
        } catch (Throwable t) {
            Log.e("Failed to preload script: " + t);
        }
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
                                clearMethodCache();
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
