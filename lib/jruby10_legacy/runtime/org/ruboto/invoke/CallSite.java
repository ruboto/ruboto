package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.CallSite. */
public abstract class CallSite {
    volatile MethodHandle target;
    private final MethodType type;

    CallSite(MethodType type) {
        this.type = type;
    }

    CallSite(MethodHandle target) {
        this.type = target.type();
        this.target = target;
    }

    public MethodType type() {
        return type;
    }

    public MethodHandle getTarget() {
        MethodHandle t = target;
        if (t == null) throw new IllegalStateException("call site has no target");
        return t;
    }

    public void setTarget(MethodHandle newTarget) {
        target = newTarget;
    }

    public MethodHandle dynamicInvoker() {
        return new Handles.Dynamic(this);
    }
}
