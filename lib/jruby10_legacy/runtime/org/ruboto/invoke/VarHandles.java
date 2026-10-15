package org.ruboto.invoke;

import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.ByteOrder;

/**
 * VarHandle implementations.  Instance fields and arrays of int, long and
 * reference type use sun.misc.Unsafe for real atomics; everything else falls
 * back to reflection guarded by a per-handle lock.
 */
final class VarHandles {
    private VarHandles() {}

    private static final sun.misc.Unsafe UNSAFE = loadUnsafe();

    private static sun.misc.Unsafe loadUnsafe() {
        for (String name : new String[]{"theUnsafe", "THE_ONE"}) {
            try {
                Field f = sun.misc.Unsafe.class.getDeclaredField(name);
                f.setAccessible(true);
                sun.misc.Unsafe u = (sun.misc.Unsafe) f.get(null);
                // Probe the operations used below so a stripped-down Unsafe
                // falls back to the locking implementation.
                Probe probe = new Probe();
                long offset = u.objectFieldOffset(Probe.class.getDeclaredField("value"));
                if (u.compareAndSwapInt(probe, offset, 0, 1) && u.getIntVolatile(probe, offset) == 1) return u;
            } catch (Throwable ignored) {
                // try the next name
            }
        }
        return null;
    }

    private static final class Probe {
        volatile int value;
    }

    static VarHandle field(Field f) {
        f.setAccessible(true);
        Class<?> t = f.getType();
        boolean isStatic = Modifier.isStatic(f.getModifiers());
        if (UNSAFE != null && !isStatic && (t == int.class || t == long.class || !t.isPrimitive())) {
            try {
                return new UnsafeField(f, UNSAFE.objectFieldOffset(f));
            } catch (Throwable ignored) {
                // fall back to the locking implementation
            }
        }
        return new LockedField(f, isStatic);
    }

    static VarHandle array(Class<?> arrayClass) {
        if (!arrayClass.isArray()) throw new IllegalArgumentException("not an array class: " + arrayClass.getName());
        Class<?> c = arrayClass.getComponentType();
        if (UNSAFE != null && (c == int.class || c == long.class || !c.isPrimitive())) {
            try {
                return new UnsafeArray(arrayClass, UNSAFE.arrayBaseOffset(arrayClass), UNSAFE.arrayIndexScale(arrayClass));
            } catch (Throwable ignored) {
                // fall back to the locking implementation
            }
        }
        return new LockedArray(arrayClass);
    }

    static VarHandle byteArrayView(Class<?> viewArrayClass, ByteOrder order) {
        Class<?> c = viewArrayClass.getComponentType();
        if (c != long.class && c != int.class && c != short.class && c != char.class
                && c != float.class && c != double.class) {
            throw new UnsupportedOperationException("byteArrayViewVarHandle(" + viewArrayClass.getName() + ")");
        }
        return new ByteArrayView(c, order == ByteOrder.BIG_ENDIAN);
    }

    static final class UnsafeField extends VarHandle {
        private final long offset;
        private final char kind;

        UnsafeField(Field f, long offset) {
            super(f.getType(), f.getDeclaringClass());
            this.offset = offset;
            Class<?> t = f.getType();
            this.kind = t == int.class ? 'I' : t == long.class ? 'J' : 'L';
        }

        @Override
        Object get(Object[] args) {
            Object o = args[0];
            if (o == null) throw new NullPointerException();
            switch (kind) {
                case 'I': return UNSAFE.getIntVolatile(o, offset);
                case 'J': return UNSAFE.getLongVolatile(o, offset);
                default: return UNSAFE.getObjectVolatile(o, offset);
            }
        }

        @Override
        void set(Object[] args, Object value) {
            Object o = args[0];
            if (o == null) throw new NullPointerException();
            switch (kind) {
                case 'I': UNSAFE.putIntVolatile(o, offset, ((Number) value).intValue()); break;
                case 'J': UNSAFE.putLongVolatile(o, offset, ((Number) value).longValue()); break;
                default: UNSAFE.putObjectVolatile(o, offset, checkType(value));
            }
        }

        @Override
        boolean compareAndSet(Object[] args, Object expected, Object value) {
            Object o = args[0];
            if (o == null) throw new NullPointerException();
            switch (kind) {
                case 'I': return UNSAFE.compareAndSwapInt(o, offset, ((Number) expected).intValue(), ((Number) value).intValue());
                case 'J': return UNSAFE.compareAndSwapLong(o, offset, ((Number) expected).longValue(), ((Number) value).longValue());
                default: return UNSAFE.compareAndSwapObject(o, offset, expected, checkType(value));
            }
        }

        private Object checkType(Object value) {
            if (value != null && !varType.isInstance(value)) {
                throw new ClassCastException("Cannot store " + value.getClass().getName() + " in " + varType.getName());
            }
            return value;
        }
    }

    static final class LockedField extends VarHandle {
        private final Field field;
        private final boolean isStatic;

        LockedField(Field field, boolean isStatic) {
            super(field.getType(), isStatic ? new Class<?>[0] : new Class<?>[]{field.getDeclaringClass()});
            this.field = field;
            this.isStatic = isStatic;
        }

        private Object target(Object[] args) {
            if (isStatic) return null;
            if (args[0] == null) throw new NullPointerException();
            return args[0];
        }

        @Override
        Object get(Object[] args) {
            try {
                synchronized (this) {
                    return field.get(target(args));
                }
            } catch (IllegalAccessException e) {
                throw new IllegalStateException(e);
            }
        }

        @Override
        void set(Object[] args, Object value) {
            try {
                synchronized (this) {
                    field.set(target(args), value);
                }
            } catch (IllegalAccessException e) {
                throw new IllegalStateException(e);
            }
        }

        @Override
        boolean compareAndSet(Object[] args, Object expected, Object value) {
            try {
                Object target = target(args);
                synchronized (this) {
                    if (!same(field.get(target), expected)) return false;
                    field.set(target, value);
                    return true;
                }
            } catch (IllegalAccessException e) {
                throw new IllegalStateException(e);
            }
        }
    }

    static final class UnsafeArray extends VarHandle {
        private final long base;
        private final int scale;
        private final char kind;

        UnsafeArray(Class<?> arrayClass, long base, int scale) {
            super(arrayClass.getComponentType(), arrayClass, int.class);
            this.base = base;
            this.scale = scale;
            Class<?> c = arrayClass.getComponentType();
            this.kind = c == int.class ? 'I' : c == long.class ? 'J' : 'L';
        }

        private long offset(Object[] args) {
            Object array = args[0];
            int index = (Integer) args[1];
            int length = Array.getLength(array);
            if (index < 0 || index >= length) throw new ArrayIndexOutOfBoundsException(index);
            return base + (long) index * scale;
        }

        @Override
        Object get(Object[] args) {
            long off = offset(args);
            switch (kind) {
                case 'I': return UNSAFE.getIntVolatile(args[0], off);
                case 'J': return UNSAFE.getLongVolatile(args[0], off);
                default: return UNSAFE.getObjectVolatile(args[0], off);
            }
        }

        @Override
        void set(Object[] args, Object value) {
            long off = offset(args);
            switch (kind) {
                case 'I': UNSAFE.putIntVolatile(args[0], off, ((Number) value).intValue()); break;
                case 'J': UNSAFE.putLongVolatile(args[0], off, ((Number) value).longValue()); break;
                default:
                    if (value != null && !args[0].getClass().getComponentType().isInstance(value)) throw new ArrayStoreException();
                    UNSAFE.putObjectVolatile(args[0], off, value);
            }
        }

        @Override
        boolean compareAndSet(Object[] args, Object expected, Object value) {
            long off = offset(args);
            switch (kind) {
                case 'I': return UNSAFE.compareAndSwapInt(args[0], off, ((Number) expected).intValue(), ((Number) value).intValue());
                case 'J': return UNSAFE.compareAndSwapLong(args[0], off, ((Number) expected).longValue(), ((Number) value).longValue());
                default:
                    if (value != null && !args[0].getClass().getComponentType().isInstance(value)) throw new ArrayStoreException();
                    return UNSAFE.compareAndSwapObject(args[0], off, expected, value);
            }
        }
    }

    static final class LockedArray extends VarHandle {
        LockedArray(Class<?> arrayClass) {
            super(arrayClass.getComponentType(), arrayClass, int.class);
        }

        @Override
        Object get(Object[] args) {
            synchronized (this) {
                return Array.get(args[0], (Integer) args[1]);
            }
        }

        @Override
        void set(Object[] args, Object value) {
            synchronized (this) {
                Array.set(args[0], (Integer) args[1], value);
            }
        }

        @Override
        boolean compareAndSet(Object[] args, Object expected, Object value) {
            synchronized (this) {
                if (!same(Array.get(args[0], (Integer) args[1]), expected)) return false;
                Array.set(args[0], (Integer) args[1], value);
                return true;
            }
        }
    }

    /** byteArrayViewVarHandle: reads/writes multi-byte values in a byte[] at a byte offset. */
    static final class ByteArrayView extends VarHandle {
        private final int size;
        private final boolean bigEndian;

        ByteArrayView(Class<?> component, boolean bigEndian) {
            super(component, byte[].class, int.class);
            this.size = component == long.class || component == double.class ? 8
                    : component == int.class || component == float.class ? 4 : 2;
            this.bigEndian = bigEndian;
        }

        private long read(byte[] a, int index) {
            if (index < 0 || index > a.length - size) throw new IndexOutOfBoundsException(Integer.toString(index));
            long r = 0;
            if (bigEndian) {
                for (int i = 0; i < size; i++) r = (r << 8) | (a[index + i] & 0xffL);
            } else {
                for (int i = size - 1; i >= 0; i--) r = (r << 8) | (a[index + i] & 0xffL);
            }
            return r;
        }

        private void write(byte[] a, int index, long v) {
            if (index < 0 || index > a.length - size) throw new IndexOutOfBoundsException(Integer.toString(index));
            for (int i = 0; i < size; i++) {
                int shift = 8 * (bigEndian ? size - 1 - i : i);
                a[index + i] = (byte) (v >>> shift);
            }
        }

        @Override
        public long getLongFromBytes(byte[] array, int index) {
            return read(array, index);
        }

        @Override
        Object get(Object[] args) {
            long v = read((byte[]) args[0], (Integer) args[1]);
            if (varType == float.class) return Float.intBitsToFloat((int) v);
            if (varType == double.class) return Double.longBitsToDouble(v);
            return Primitives.convert(v, varType);
        }

        @Override
        void set(Object[] args, Object value) {
            long v;
            if (varType == float.class) v = Float.floatToRawIntBits(((Number) value).floatValue());
            else if (varType == double.class) v = Double.doubleToRawLongBits(((Number) value).doubleValue());
            else v = value instanceof Character ? (Character) value : ((Number) value).longValue();
            synchronized (this) {
                write((byte[]) args[0], (Integer) args[1], v);
            }
        }

        @Override
        boolean compareAndSet(Object[] args, Object expected, Object value) {
            synchronized (this) {
                if (!same(get(args), Primitives.convert(expected, varType))) return false;
                set(args, value);
                return true;
            }
        }
    }
}
