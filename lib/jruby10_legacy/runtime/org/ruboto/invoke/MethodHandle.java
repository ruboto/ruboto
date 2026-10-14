package org.ruboto.invoke;

import java.lang.reflect.Array;
import java.util.List;

/**
 * Stand-in for java.lang.invoke.MethodHandle.  Arguments travel boxed in an
 * Object[]; signature-polymorphic invokeExact/invoke call sites in jruby-core
 * are rewritten at build time into static bridges (org.ruboto.invoke.Poly)
 * that box their arguments and call {@link #invokeArgs}.
 */
public abstract class MethodHandle {
    final MethodType type;

    MethodHandle(MethodType type) {
        this.type = type;
    }

    public MethodType type() {
        return type;
    }

    /** Invokes the handle with boxed arguments; returns a boxed result (null for void). */
    public abstract Object invokeArgs(Object[] args) throws Throwable;

    public Object invokeWithArguments(Object... args) throws Throwable {
        return invokeArgs(args == null ? new Object[]{null} : args);
    }

    public Object invokeWithArguments(List<?> args) throws Throwable {
        return invokeWithArguments(args.toArray());
    }

    public MethodHandle asType(MethodType newType) {
        if (newType.equals(type)) return this;
        if (newType.parameterCount() != type.parameterCount()) {
            throw new WrongMethodTypeException("cannot convert " + type + " to " + newType);
        }
        return new Handles.Converting(this, newType);
    }

    public MethodHandle bindTo(Object x) {
        return MethodHandles.insertArguments(this, 0, x);
    }

    public MethodHandle asSpreader(Class<?> arrayType, int arrayLength) {
        return asSpreader(type.parameterCount() - arrayLength, arrayType, arrayLength);
    }

    public MethodHandle asSpreader(final int spreadArgPos, Class<?> arrayType, final int arrayLength) {
        MethodType newType = type.dropParameterTypes(spreadArgPos, spreadArgPos + arrayLength)
                .insertParameterTypes(spreadArgPos, arrayType);
        final MethodHandle target = this;
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object array = args[spreadArgPos];
                int len = array == null ? 0 : Array.getLength(array);
                if (len != arrayLength) throw new IllegalArgumentException("array is not of length " + arrayLength);
                Object[] spread = new Object[args.length - 1 + arrayLength];
                System.arraycopy(args, 0, spread, 0, spreadArgPos);
                for (int i = 0; i < arrayLength; i++) spread[spreadArgPos + i] = Array.get(array, i);
                System.arraycopy(args, spreadArgPos + 1, spread, spreadArgPos + arrayLength, args.length - spreadArgPos - 1);
                return target.invokeArgs(spread);
            }
        };
    }

    public MethodHandle asCollector(Class<?> arrayType, int arrayLength) {
        return asCollector(type.parameterCount() - 1, arrayType, arrayLength);
    }

    public MethodHandle asCollector(final int collectArgPos, final Class<?> arrayType, final int arrayLength) {
        Class<?>[] collected = new Class<?>[arrayLength];
        java.util.Arrays.fill(collected, arrayType.getComponentType());
        MethodType newType = type.dropParameterTypes(collectArgPos, collectArgPos + 1)
                .insertParameterTypes(collectArgPos, collected);
        final MethodHandle target = this;
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                return target.invokeArgs(Handles.collect(args, collectArgPos, arrayLength, arrayType.getComponentType()));
            }
        };
    }

    public MethodHandle asVarargsCollector(Class<?> arrayType) {
        return new Handles.VarargsCollector(this, arrayType);
    }

    public boolean isVarargsCollector() {
        return false;
    }

    public MethodHandle asFixedArity() {
        return this;
    }

    public MethodHandle withVarargs(boolean makeVarargs) {
        if (!makeVarargs) return asFixedArity();
        return asVarargsCollector(type.lastParameterType());
    }

    @Override
    public String toString() {
        return "MethodHandle" + type;
    }
}
