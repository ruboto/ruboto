package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.SwitchPoint. */
public class SwitchPoint {
    private volatile boolean invalidated;

    public boolean hasBeenInvalidated() {
        return invalidated;
    }

    public MethodHandle guardWithTest(final MethodHandle target, final MethodHandle fallback) {
        return new MethodHandle(target.type()) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                return (invalidated ? fallback : target).invokeArgs(args);
            }
        };
    }

    public static void invalidateAll(SwitchPoint[] switchPoints) {
        for (SwitchPoint sp : switchPoints) sp.invalidated = true;
    }
}
