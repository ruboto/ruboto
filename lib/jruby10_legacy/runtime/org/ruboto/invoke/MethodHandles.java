package org.ruboto.invoke;

import java.lang.reflect.Array;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.nio.ByteOrder;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Stand-in for java.lang.invoke.MethodHandles.  Lookups resolve members with
 * reflection and ignore access checks (members are made accessible), which is
 * what JRuby's own full-privilege lookups expect.
 */
public final class MethodHandles {
    private MethodHandles() {}

    private static final Lookup FULL = new Lookup(Object.class);

    public static Lookup lookup() {
        return FULL;
    }

    public static Lookup publicLookup() {
        return FULL;
    }

    public static Lookup privateLookupIn(Class<?> targetClass, Lookup caller) {
        return new Lookup(targetClass);
    }

    public static final class Lookup {
        public static final int PUBLIC = 1;
        public static final int PRIVATE = 2;
        public static final int PROTECTED = 4;
        public static final int PACKAGE = 8;
        public static final int MODULE = 16;
        public static final int UNCONDITIONAL = 32;
        public static final int ORIGINAL = 64;

        private final Class<?> lookupClass;

        Lookup(Class<?> lookupClass) {
            this.lookupClass = lookupClass;
        }

        public Class<?> lookupClass() { return lookupClass; }

        public int lookupModes() { return PUBLIC | PRIVATE | PROTECTED | PACKAGE | MODULE; }

        public boolean hasPrivateAccess() { return true; }

        public boolean hasFullPrivilegeAccess() { return true; }

        public Lookup in(Class<?> requestedLookupClass) { return new Lookup(requestedLookupClass); }

        public Lookup dropLookupMode(int modeToDrop) { return this; }

        public Class<?> findClass(String targetName) throws ClassNotFoundException {
            return Class.forName(targetName, false, lookupClass.getClassLoader());
        }

        public Class<?> defineClass(byte[] bytes) {
            throw new UnsupportedOperationException("Lookup.defineClass: Android cannot load JVM bytecode");
        }

        public MethodHandle findStatic(Class<?> refc, String name, MethodType type) throws NoSuchMethodException, IllegalAccessException {
            Method m = findMethod(refc, name, type);
            if (!Modifier.isStatic(m.getModifiers())) throw new IllegalAccessException("not static: " + m);
            return new Handles.StaticMethod(m);
        }

        public MethodHandle findVirtual(Class<?> refc, String name, MethodType type) throws NoSuchMethodException, IllegalAccessException {
            Method m = findMethod(refc, name, type);
            if (Modifier.isStatic(m.getModifiers())) throw new IllegalAccessException("static: " + m);
            return new Handles.VirtualMethod(m, refc);
        }

        /**
         * Reflection cannot express invokespecial, so this dispatches
         * virtually.  JRuby only uses it from its JIT, which is off on Android.
         */
        public MethodHandle findSpecial(Class<?> refc, String name, MethodType type, Class<?> specialCaller) throws NoSuchMethodException, IllegalAccessException {
            Method m = findMethod(refc, name, type);
            return new Handles.VirtualMethod(m, specialCaller);
        }

        public MethodHandle findConstructor(Class<?> refc, MethodType type) throws NoSuchMethodException, IllegalAccessException {
            Constructor<?> c = refc.getDeclaredConstructor(type.parameterArray());
            return new Handles.ConstructorHandle(c);
        }

        public MethodHandle findGetter(Class<?> refc, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return new Handles.Getter(findField(refc, name, type, false));
        }

        public MethodHandle findSetter(Class<?> refc, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return new Handles.Setter(findField(refc, name, type, false));
        }

        public MethodHandle findStaticGetter(Class<?> refc, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return new Handles.Getter(findField(refc, name, type, true));
        }

        public MethodHandle findStaticSetter(Class<?> refc, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return new Handles.Setter(findField(refc, name, type, true));
        }

        public VarHandle findVarHandle(Class<?> recv, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return VarHandles.field(findField(recv, name, type, false));
        }

        public VarHandle findStaticVarHandle(Class<?> decl, String name, Class<?> type) throws NoSuchFieldException, IllegalAccessException {
            return VarHandles.field(findField(decl, name, type, true));
        }

        public VarHandle unreflectVarHandle(Field f) {
            return VarHandles.field(f);
        }

        public MethodHandle unreflect(Method m) {
            if (Modifier.isStatic(m.getModifiers())) return new Handles.StaticMethod(m);
            return new Handles.VirtualMethod(m, m.getDeclaringClass());
        }

        public MethodHandle unreflectSpecial(Method m, Class<?> specialCaller) {
            return new Handles.VirtualMethod(m, specialCaller);
        }

        public MethodHandle unreflectConstructor(Constructor<?> c) {
            return new Handles.ConstructorHandle(c);
        }

        public MethodHandle unreflectGetter(Field f) {
            return new Handles.Getter(f);
        }

        public MethodHandle unreflectSetter(Field f) {
            return new Handles.Setter(f);
        }

        @Override
        public String toString() {
            return lookupClass.getName();
        }
    }

    static Method findMethod(Class<?> refc, String name, MethodType type) throws NoSuchMethodException {
        Class<?>[] params = type.parameterArray();
        Deque<Class<?>> queue = new ArrayDeque<Class<?>>();
        Set<Class<?>> seen = new HashSet<Class<?>>();
        queue.add(refc);
        while (!queue.isEmpty()) {
            Class<?> c = queue.poll();
            if (!seen.add(c)) continue;
            for (Method m : c.getDeclaredMethods()) {
                if (m.getName().equals(name) && m.getReturnType() == type.returnType()
                        && java.util.Arrays.equals(m.getParameterTypes(), params)) {
                    return m;
                }
            }
            if (c.getSuperclass() != null) queue.add(c.getSuperclass());
            for (Class<?> i : c.getInterfaces()) queue.add(i);
        }
        if (refc.isInterface()) {
            try {
                return findMethod(Object.class, name, type);
            } catch (NoSuchMethodException ignored) {
                // fall through to the error below
            }
        }
        throw new NoSuchMethodException(refc.getName() + "." + name + type);
    }

    static Field findField(Class<?> refc, String name, Class<?> type, boolean wantStatic) throws NoSuchFieldException, IllegalAccessException {
        for (Class<?> c = refc; c != null; c = c.getSuperclass()) {
            try {
                Field f = c.getDeclaredField(name);
                if (f.getType() != type) throw new NoSuchFieldException(refc.getName() + "." + name + ":" + type.getName());
                if (Modifier.isStatic(f.getModifiers()) != wantStatic) {
                    throw new IllegalAccessException((wantStatic ? "not static: " : "static: ") + f);
                }
                f.setAccessible(true);
                return f;
            } catch (NoSuchFieldException ignored) {
                // keep looking in the superclass
            }
        }
        throw new NoSuchFieldException(refc.getName() + "." + name);
    }

    // ---------------------------------------------------------------- simple handles

    public static MethodHandle constant(Class<?> type, Object value) {
        return new Handles.Constant(type, value);
    }

    public static MethodHandle identity(Class<?> type) {
        return new Handles.Identity(type);
    }

    public static MethodHandle zero(Class<?> type) {
        return new Handles.Constant(type, Primitives.zero(type));
    }

    public static MethodHandle empty(MethodType type) {
        return dropArguments(zero(type.returnType()), 0, type.parameterArray());
    }

    public static MethodHandle throwException(Class<?> returnType, Class<? extends Throwable> exType) {
        return new MethodHandle(MethodType.methodType(returnType, exType)) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                throw (Throwable) args[0];
            }
        };
    }

    public static MethodHandle arrayConstructor(final Class<?> arrayClass) {
        return new MethodHandle(MethodType.methodType(arrayClass, int.class)) {
            @Override
            public Object invokeArgs(Object[] args) {
                return Array.newInstance(arrayClass.getComponentType(), (Integer) args[0]);
            }
        };
    }

    public static MethodHandle arrayLength(Class<?> arrayClass) {
        return new MethodHandle(MethodType.methodType(int.class, arrayClass)) {
            @Override
            public Object invokeArgs(Object[] args) {
                return Array.getLength(args[0]);
            }
        };
    }

    public static MethodHandle arrayElementGetter(Class<?> arrayClass) {
        return new MethodHandle(MethodType.methodType(arrayClass.getComponentType(), arrayClass, int.class)) {
            @Override
            public Object invokeArgs(Object[] args) {
                return Array.get(args[0], (Integer) args[1]);
            }
        };
    }

    public static MethodHandle arrayElementSetter(Class<?> arrayClass) {
        return new MethodHandle(MethodType.methodType(void.class, arrayClass, int.class, arrayClass.getComponentType())) {
            @Override
            public Object invokeArgs(Object[] args) {
                Array.set(args[0], (Integer) args[1], args[2]);
                return null;
            }
        };
    }

    public static VarHandle arrayElementVarHandle(Class<?> arrayClass) {
        return VarHandles.array(arrayClass);
    }

    public static VarHandle byteArrayViewVarHandle(Class<?> viewArrayClass, ByteOrder byteOrder) {
        return VarHandles.byteArrayView(viewArrayClass, byteOrder);
    }

    public static MethodHandle invoker(MethodType type) {
        return new MethodHandle(type.insertParameterTypes(0, MethodHandle.class)) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                return ((MethodHandle) args[0]).invokeArgs(Handles.copyOfRange(args, 1, args.length));
            }
        };
    }

    public static MethodHandle exactInvoker(MethodType type) {
        return invoker(type);
    }

    public static MethodHandle spreadInvoker(MethodType type, int leadingArgCount) {
        return invoker(type).asSpreader(Object[].class, type.parameterCount() - leadingArgCount);
    }

    // ---------------------------------------------------------------- combinators

    public static MethodHandle explicitCastArguments(MethodHandle target, MethodType newType) {
        return target.asType(newType);
    }

    public static MethodHandle insertArguments(final MethodHandle target, final int pos, Object... values) {
        final Object[] inserted = values.clone();
        MethodType newType = target.type.dropParameterTypes(pos, pos + inserted.length);
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object[] all = new Object[args.length + inserted.length];
                System.arraycopy(args, 0, all, 0, pos);
                System.arraycopy(inserted, 0, all, pos, inserted.length);
                System.arraycopy(args, pos, all, pos + inserted.length, args.length - pos);
                return target.invokeArgs(all);
            }
        };
    }

    public static MethodHandle dropArguments(final MethodHandle target, final int pos, final Class<?>... valueTypes) {
        MethodType newType = target.type.insertParameterTypes(pos, valueTypes);
        final int dropped = valueTypes.length;
        if (dropped == 0) return target;
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object[] kept = new Object[args.length - dropped];
                System.arraycopy(args, 0, kept, 0, pos);
                System.arraycopy(args, pos + dropped, kept, pos, args.length - pos - dropped);
                return target.invokeArgs(kept);
            }
        };
    }

    public static MethodHandle dropArguments(MethodHandle target, int pos, List<Class<?>> valueTypes) {
        return dropArguments(target, pos, valueTypes.toArray(new Class<?>[0]));
    }

    public static MethodHandle filterArguments(final MethodHandle target, final int pos, MethodHandle... filters) {
        final MethodHandle[] fs = filters.clone();
        MethodType newType = target.type;
        for (int i = 0; i < fs.length; i++) {
            if (fs[i] != null) newType = newType.changeParameterType(pos + i, fs[i].type.parameterType(0));
        }
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object[] filtered = args.clone();
                for (int i = 0; i < fs.length; i++) {
                    if (fs[i] != null) filtered[pos + i] = fs[i].invokeArgs(new Object[]{args[pos + i]});
                }
                return target.invokeArgs(filtered);
            }
        };
    }

    public static MethodHandle filterReturnValue(final MethodHandle target, final MethodHandle filter) {
        MethodType newType = target.type.changeReturnType(filter.type.returnType());
        final boolean voidTarget = target.type.returnType() == void.class;
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object r = target.invokeArgs(args);
                return filter.invokeArgs(voidTarget ? Handles.NO_ARGS : new Object[]{r});
            }
        };
    }

    public static MethodHandle foldArguments(MethodHandle target, MethodHandle combiner) {
        return foldArguments(target, 0, combiner);
    }

    public static MethodHandle foldArguments(final MethodHandle target, final int pos, final MethodHandle combiner) {
        final boolean voidCombiner = combiner.type.returnType() == void.class;
        final int combinerArgs = combiner.type.parameterCount();
        MethodType newType = voidCombiner ? target.type : target.type.dropParameterTypes(pos, pos + 1);
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object c = combiner.invokeArgs(Handles.copyOfRange(args, pos, pos + combinerArgs));
                if (voidCombiner) return target.invokeArgs(args);
                Object[] all = new Object[args.length + 1];
                System.arraycopy(args, 0, all, 0, pos);
                all[pos] = c;
                System.arraycopy(args, pos, all, pos + 1, args.length - pos);
                return target.invokeArgs(all);
            }
        };
    }

    public static MethodHandle collectArguments(final MethodHandle target, final int pos, final MethodHandle filter) {
        final boolean voidFilter = filter.type.returnType() == void.class;
        final int filterArgs = filter.type.parameterCount();
        MethodType newType = (voidFilter ? target.type : target.type.dropParameterTypes(pos, pos + 1))
                .insertParameterTypes(pos, filter.type.parameterArray());
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object r = filter.invokeArgs(Handles.copyOfRange(args, pos, pos + filterArgs));
                int keep = voidFilter ? 0 : 1;
                Object[] all = new Object[args.length - filterArgs + keep];
                System.arraycopy(args, 0, all, 0, pos);
                if (!voidFilter) all[pos] = r;
                System.arraycopy(args, pos + filterArgs, all, pos + keep, args.length - pos - filterArgs);
                return target.invokeArgs(all);
            }
        };
    }

    public static MethodHandle guardWithTest(final MethodHandle test, final MethodHandle target, final MethodHandle fallback) {
        final int testArgs = test.type.parameterCount();
        return new MethodHandle(target.type) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object[] testArgv = testArgs == args.length ? args : Handles.copyOfRange(args, 0, testArgs);
                boolean ok = (Boolean) Primitives.convert(test.invokeArgs(testArgv), boolean.class);
                return (ok ? target : fallback).invokeArgs(args);
            }
        };
    }

    public static MethodHandle catchException(final MethodHandle target, final Class<? extends Throwable> exType, final MethodHandle handler) {
        final int handlerArgs = handler.type.parameterCount() - 1;
        return new MethodHandle(target.type) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                try {
                    return target.invokeArgs(args);
                } catch (Throwable t) {
                    if (!exType.isInstance(t)) throw t;
                    Object[] h = new Object[handlerArgs + 1];
                    h[0] = t;
                    System.arraycopy(args, 0, h, 1, handlerArgs);
                    return handler.invokeArgs(h);
                }
            }
        };
    }

    public static MethodHandle permuteArguments(final MethodHandle target, MethodType newType, int... reorder) {
        final int[] order = reorder.clone();
        return new MethodHandle(newType) {
            @Override
            public Object invokeArgs(Object[] args) throws Throwable {
                Object[] permuted = new Object[order.length];
                for (int i = 0; i < order.length; i++) permuted[i] = args[order[i]];
                return target.invokeArgs(permuted);
            }
        };
    }
}
