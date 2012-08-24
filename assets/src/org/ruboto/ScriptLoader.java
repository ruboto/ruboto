package org.ruboto;

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
}
