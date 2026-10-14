package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.MutableCallSite. */
public class MutableCallSite extends CallSite {
    public MutableCallSite(MethodType type) {
        super(type);
        target = new Handles.Unsupported(type, "uninitialized call site");
    }

    public MutableCallSite(MethodHandle target) {
        super(target);
    }

    public static void syncAll(MutableCallSite[] sites) {
        // Targets are volatile; nothing to do.
    }
}
