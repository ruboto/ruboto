import org.jruby.embed.ScriptingContainer;

class JRUBY_6785 {
    public JRUBY_6785() {}

    public static void main(String[] args) throws Exception {
        ScriptingContainer sc = new ScriptingContainer();
        sc.put("JRUBY_6785", sc.runScriptlet("Java::JRUBY_6785"));
        sc.runScriptlet("class JRUBY_6785 ; def ruby_method ; puts 'Success!' ; end ; end");
        sc.callMethod(new JRUBY_6785(), "ruby_method");
    }
}
