package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.VolatileCallSite. */
public class VolatileCallSite extends CallSite {
    public VolatileCallSite(MethodType type) {
        super(type);
        target = new Handles.Unsupported(type, "uninitialized call site");
    }

    public VolatileCallSite(MethodHandle target) {
        super(target);
    }
}
