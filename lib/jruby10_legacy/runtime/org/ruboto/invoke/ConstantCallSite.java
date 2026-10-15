package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.ConstantCallSite. */
public class ConstantCallSite extends CallSite {
    public ConstantCallSite(MethodHandle target) {
        super(target);
    }

    @Override
    public final void setTarget(MethodHandle newTarget) {
        throw new UnsupportedOperationException("ConstantCallSite");
    }

    @Override
    public final MethodHandle dynamicInvoker() {
        return getTarget();
    }
}
