package org.ruboto.invoke;

/**
 * Stand-in for direct (non-invokedynamic) calls to
 * java.lang.invoke.LambdaMetafactory.  Lambdas in jruby-core's own code are
 * desugared by d8 and never get here; only reflective lambda creation does,
 * which needs runtime class generation.
 */
public final class LambdaMetafactory {
    public static final int FLAG_SERIALIZABLE = 1;
    public static final int FLAG_MARKERS = 2;
    public static final int FLAG_BRIDGES = 4;

    private LambdaMetafactory() {}

    public static CallSite metafactory(MethodHandles.Lookup caller, String interfaceMethodName, MethodType factoryType,
                                       MethodType interfaceMethodType, MethodHandle implementation, MethodType dynamicMethodType) {
        throw new UnsupportedOperationException("LambdaMetafactory is not available on this Android version");
    }

    public static CallSite altMetafactory(MethodHandles.Lookup caller, String interfaceMethodName, MethodType factoryType, Object... args) {
        throw new UnsupportedOperationException("LambdaMetafactory is not available on this Android version");
    }
}
