package org.ruboto;

public class ScriptLoader {
   /**
    Return true if we are called from JRuby.
    */
    public static boolean isCalledFromJRuby() {
        StackTraceElement[] stackTraceElements = Thread.currentThread().getStackTrace();
        int maxLookBack = Math.min(10, stackTraceElements.length);
        for(int i = 0; i < maxLookBack ; i++){
            System.out.println("Stack frame("+i+"): " + stackTraceElements[i].getClassName() + "." +  stackTraceElements[i].getMethodName());
            if (stackTraceElements[i].getClassName().startsWith("org.jruby.javasupport.JavaMethod")) {
                System.out.println("Called from JRuby");
                return true;
            }
        }
        System.out.println("Called from Java");
        return false;
    }
}
