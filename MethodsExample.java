import org.jruby.embed.ScriptingContainer;

class MethodsExample {
    public void myJavaMethod(String message) {
        System.out.println("myJavaMethod called: " + message);
    }

    public static void main(String[] args) {
        ScriptingContainer sc = new ScriptingContainer();
        MethodsExample me = new MethodsExample();

        sc.put("MethodsExample", sc.runScriptlet("Java::MethodsExample"));
        sc.runScriptlet("class MethodsExample ; def my_ruby_method(msg) ; puts \"my_ruby_method called: #{msg}\" ; end ; end");

        sc.put("$java_instance", me);

        // Should be called since a Ruby method is defined
        if ((Boolean) sc.runScriptlet("MethodsExample.instance_methods(false).include?(:my_ruby_method)")) {
            sc.put("$ruby_arg", "ruby msg");
            sc.runScriptlet("$java_instance.my_ruby_method($ruby_arg)");
        }

        // Should not be called
        if ((Boolean) sc.runScriptlet("MethodsExample.instance_methods(false).include?(:my_java_method)")) {
            sc.put("$java_arg", "java msg");
            sc.runScriptlet("$java_instance.my_java_method($java_arg)");
        }

        // Should not be called
        if ((Boolean) sc.runScriptlet("MethodsExample.instance_methods(false).include?(:myJavaMethod)")) {
            sc.put("$java_arg", "java msg");
            sc.runScriptlet("$java_instance.myJavaMethod($java_arg)");
        }
    }
}
