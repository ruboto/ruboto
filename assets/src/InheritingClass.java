package THE_PACKAGE;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;
import org.ruboto.Script;

public class THE_RUBOTO_CLASS THE_ACTION THE_ANDROID_CLASS {
  private Ruby __ruby__;

THE_CONSTANTS
  private IRubyObject[] callbackProcs = new IRubyObject[CONSTANTS_COUNT];

THE_CONSTRUCTORS

  private Ruby getRuby() {
    if (__ruby__ == null) __ruby__ = Script.getRuby();
    return __ruby__;
  }

  public void setCallbackProc(int id, IRubyObject obj) {
    callbackProcs[id] = obj;
  }
	
THE_METHODS
}
