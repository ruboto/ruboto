package org.ruboto.invoke;

/** Boxing helpers shared by the java.lang.invoke stand-ins. */
final class Primitives {
    private Primitives() {}

    static boolean isWrapper(Class<?> c) {
        return c == Integer.class || c == Long.class || c == Boolean.class || c == Byte.class
                || c == Short.class || c == Character.class || c == Float.class || c == Double.class
                || c == Void.class;
    }

    static Class<?> wrap(Class<?> c) {
        if (!c.isPrimitive()) return c;
        if (c == int.class) return Integer.class;
        if (c == long.class) return Long.class;
        if (c == boolean.class) return Boolean.class;
        if (c == byte.class) return Byte.class;
        if (c == short.class) return Short.class;
        if (c == char.class) return Character.class;
        if (c == float.class) return Float.class;
        if (c == double.class) return Double.class;
        return Void.class;
    }

    static Class<?> unwrap(Class<?> c) {
        if (c == Integer.class) return int.class;
        if (c == Long.class) return long.class;
        if (c == Boolean.class) return boolean.class;
        if (c == Byte.class) return byte.class;
        if (c == Short.class) return short.class;
        if (c == Character.class) return char.class;
        if (c == Float.class) return float.class;
        if (c == Double.class) return double.class;
        if (c == Void.class) return void.class;
        return c;
    }

    /**
     * Converts a boxed value to the representation of {@code to}, following
     * the primitive widening/narrowing that MethodHandle.asType and
     * explicitCastArguments allow.  Reference types are only cast-checked.
     */
    static Object convert(Object v, Class<?> to) {
        if (to == void.class) return null;
        if (!to.isPrimitive()) {
            if (v != null && !to.isInstance(v) && !isWrapper(to)) {
                throw new ClassCastException("Cannot cast " + v.getClass().getName() + " to " + to.getName());
            }
            return v;
        }
        if (v == null) return zero(to);
        if (to == boolean.class) {
            if (v instanceof Boolean) return v;
            return (asLong(v) & 1) != 0;
        }
        if (to == char.class) {
            if (v instanceof Character) return v;
            return (char) asLong(v);
        }
        if (to == int.class) return v instanceof Integer ? v : (int) asLong(v);
        if (to == long.class) return v instanceof Long ? v : asLong(v);
        if (to == byte.class) return v instanceof Byte ? v : (byte) asLong(v);
        if (to == short.class) return v instanceof Short ? v : (short) asLong(v);
        if (to == float.class) return v instanceof Float ? v : (float) asDouble(v);
        if (to == double.class) return v instanceof Double ? v : asDouble(v);
        return v;
    }

    static Object zero(Class<?> c) {
        if (!c.isPrimitive() || c == void.class) return null;
        if (c == boolean.class) return Boolean.FALSE;
        if (c == char.class) return (char) 0;
        if (c == int.class) return 0;
        if (c == long.class) return 0L;
        if (c == byte.class) return (byte) 0;
        if (c == short.class) return (short) 0;
        if (c == float.class) return 0f;
        return 0d;
    }

    private static long asLong(Object v) {
        if (v instanceof Number) return ((Number) v).longValue();
        if (v instanceof Character) return (Character) v;
        if (v instanceof Boolean) return ((Boolean) v) ? 1 : 0;
        throw new ClassCastException("Cannot convert " + v.getClass().getName() + " to a primitive");
    }

    private static double asDouble(Object v) {
        if (v instanceof Number) return ((Number) v).doubleValue();
        return asLong(v);
    }
}
