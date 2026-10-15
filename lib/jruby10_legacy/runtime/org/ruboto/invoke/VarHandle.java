package org.ruboto.invoke;

/**
 * Stand-in for java.lang.invoke.VarHandle.  Signature-polymorphic access
 * calls in jruby-core are rewritten at build time into static bridges
 * (org.ruboto.invoke.Poly) that box their arguments and call
 * {@link #access}.  Every access mode is treated as volatile.
 */
public abstract class VarHandle {
    public enum AccessMode {
        GET("get"), SET("set"),
        GET_VOLATILE("getVolatile"), SET_VOLATILE("setVolatile"),
        GET_ACQUIRE("getAcquire"), SET_RELEASE("setRelease"),
        GET_OPAQUE("getOpaque"), SET_OPAQUE("setOpaque"),
        COMPARE_AND_SET("compareAndSet"),
        COMPARE_AND_EXCHANGE("compareAndExchange"),
        COMPARE_AND_EXCHANGE_ACQUIRE("compareAndExchangeAcquire"),
        COMPARE_AND_EXCHANGE_RELEASE("compareAndExchangeRelease"),
        WEAK_COMPARE_AND_SET_PLAIN("weakCompareAndSetPlain"),
        WEAK_COMPARE_AND_SET("weakCompareAndSet"),
        WEAK_COMPARE_AND_SET_ACQUIRE("weakCompareAndSetAcquire"),
        WEAK_COMPARE_AND_SET_RELEASE("weakCompareAndSetRelease"),
        GET_AND_SET("getAndSet"), GET_AND_SET_ACQUIRE("getAndSetAcquire"), GET_AND_SET_RELEASE("getAndSetRelease"),
        GET_AND_ADD("getAndAdd"), GET_AND_ADD_ACQUIRE("getAndAddAcquire"), GET_AND_ADD_RELEASE("getAndAddRelease"),
        GET_AND_BITWISE_OR("getAndBitwiseOr"), GET_AND_BITWISE_OR_RELEASE("getAndBitwiseOrRelease"),
        GET_AND_BITWISE_OR_ACQUIRE("getAndBitwiseOrAcquire"),
        GET_AND_BITWISE_AND("getAndBitwiseAnd"), GET_AND_BITWISE_AND_RELEASE("getAndBitwiseAndRelease"),
        GET_AND_BITWISE_AND_ACQUIRE("getAndBitwiseAndAcquire"),
        GET_AND_BITWISE_XOR("getAndBitwiseXor"), GET_AND_BITWISE_XOR_RELEASE("getAndBitwiseXorRelease"),
        GET_AND_BITWISE_XOR_ACQUIRE("getAndBitwiseXorAcquire");

        private final String methodName;

        AccessMode(String methodName) {
            this.methodName = methodName;
        }

        public String methodName() {
            return methodName;
        }

        public static AccessMode valueFromMethodName(String methodName) {
            for (AccessMode m : values()) if (m.methodName.equals(methodName)) return m;
            throw new IllegalArgumentException("No AccessMode value for method name " + methodName);
        }
    }

    private static volatile int fenceSink;

    final Class<?> varType;
    final Class<?>[] coordinateTypes;

    VarHandle(Class<?> varType, Class<?>... coordinateTypes) {
        this.varType = varType;
        this.coordinateTypes = coordinateTypes;
    }

    public Class<?> varType() {
        return varType;
    }

    public java.util.List<Class<?>> coordinateTypes() {
        return java.util.Arrays.asList(coordinateTypes.clone());
    }

    /** Reads the variable addressed by the leading coordinate arguments. */
    abstract Object get(Object[] args);

    /** Writes {@code value} to the variable addressed by the leading coordinate arguments. */
    abstract void set(Object[] args, Object value);

    /** Atomically replaces {@code expected} with {@code value}. */
    abstract boolean compareAndSet(Object[] args, Object expected, Object value);

    /** Fast path for byte-array views, used by the generated Poly bridge for get([BI)J. */
    public long getLongFromBytes(byte[] array, int index) {
        return ((Number) get(new Object[]{array, index})).longValue();
    }

    /** Entry point for the generated Poly bridges. */
    public final Object access(String methodName, Object[] args) {
        int n = coordinateTypes.length;
        if (varType.isPrimitive() && args.length > n) {
            // Call sites may box a narrower type (e.g. an int literal for a
            // long field); compare and store values as varType.
            args = args.clone();
            for (int i = n; i < args.length; i++) args[i] = Primitives.convert(args[i], varType);
        }
        switch (methodName) {
            case "get": case "getVolatile": case "getAcquire": case "getOpaque":
                return get(args);
            case "set": case "setVolatile": case "setRelease": case "setOpaque":
                set(args, args[n]);
                return null;
            case "compareAndSet": case "weakCompareAndSet": case "weakCompareAndSetPlain":
            case "weakCompareAndSetAcquire": case "weakCompareAndSetRelease":
                return compareAndSet(args, args[n], args[n + 1]);
            case "compareAndExchange": case "compareAndExchangeAcquire": case "compareAndExchangeRelease":
                while (true) {
                    Object current = get(args);
                    if (!same(current, args[n])) return current;
                    if (compareAndSet(args, current, args[n + 1])) return current;
                }
            case "getAndSet": case "getAndSetAcquire": case "getAndSetRelease":
                while (true) {
                    Object current = get(args);
                    if (compareAndSet(args, current, args[n])) return current;
                }
            case "getAndAdd": case "getAndAddAcquire": case "getAndAddRelease":
                return getAndUpdate(args, args[n], '+');
            case "getAndBitwiseOr": case "getAndBitwiseOrAcquire": case "getAndBitwiseOrRelease":
                return getAndUpdate(args, args[n], '|');
            case "getAndBitwiseAnd": case "getAndBitwiseAndAcquire": case "getAndBitwiseAndRelease":
                return getAndUpdate(args, args[n], '&');
            case "getAndBitwiseXor": case "getAndBitwiseXorAcquire": case "getAndBitwiseXorRelease":
                return getAndUpdate(args, args[n], '^');
            default:
                throw new UnsupportedOperationException("VarHandle." + methodName);
        }
    }

    private Object getAndUpdate(Object[] args, Object operand, char op) {
        while (true) {
            Object current = get(args);
            if (compareAndSet(args, current, combine(current, operand, op))) return current;
        }
    }

    private Object combine(Object current, Object operand, char op) {
        Class<?> t = varType;
        if (t == boolean.class) {
            boolean a = (Boolean) current, b = (Boolean) operand;
            return op == '|' ? a | b : op == '&' ? a & b : a ^ b;
        }
        if (t == float.class) return ((Number) current).floatValue() + ((Number) operand).floatValue();
        if (t == double.class) return ((Number) current).doubleValue() + ((Number) operand).doubleValue();
        long a = current instanceof Character ? (Character) current : ((Number) current).longValue();
        long b = operand instanceof Character ? (Character) operand : ((Number) operand).longValue();
        long r = op == '+' ? a + b : op == '|' ? (a | b) : op == '&' ? (a & b) : (a ^ b);
        return Primitives.convert(r, t);
    }

    /** VarHandle comparison: identity for references, value equality for primitives. */
    boolean same(Object a, Object b) {
        if (!varType.isPrimitive()) return a == b;
        return a == null ? b == null : a.equals(b);
    }

    public MethodType accessModeType(AccessMode mode) {
        MethodType coords = MethodType.methodType(void.class, coordinateTypes);
        String name = mode.methodName();
        if (name.startsWith("get") && !name.startsWith("getAnd")) return coords.changeReturnType(varType);
        if (name.startsWith("set")) return coords.appendParameterTypes(varType);
        if (name.contains("ompareAndSet")) return coords.appendParameterTypes(varType, varType).changeReturnType(boolean.class);
        if (name.startsWith("compareAndExchange")) return coords.appendParameterTypes(varType, varType).changeReturnType(varType);
        return coords.appendParameterTypes(varType).changeReturnType(varType);
    }

    public MethodHandle toMethodHandle(final AccessMode mode) {
        return new MethodHandle(accessModeType(mode)) {
            @Override
            public Object invokeArgs(Object[] args) {
                return access(mode.methodName(), args);
            }
        };
    }

    public boolean isAccessModeSupported(AccessMode mode) {
        return true;
    }

    public static void fullFence() {
        fenceSink++;
    }

    public static void acquireFence() {
        int ignored = fenceSink;
    }

    public static void releaseFence() {
        fenceSink = 0;
    }

    public static void loadLoadFence() {
        int ignored = fenceSink;
    }

    public static void storeStoreFence() {
        fenceSink = 0;
    }
}
